r 'timezone'

module ICalPal
  # Class representing items from the <tt>CalendarItem</tt> table
  class Event
    include ICalPal

    # Standard accessor with special handling for +sdate+ and +edate+.  Setting
    # those will also set +sctime+ and +ectime+ respectively.
    #
    # @param k [String] Key/property name
    # @param v [Object] Key/property value
    def []=(k, v)
      @self[k] = v

      @self['sctime'] = Time.at(@self['sdate'].to_i, in: '+00:00') if k == 'sdate'
      @self['ectime'] = Time.at(@self['edate'].to_i, in: '+00:00') if k == 'edate'
    end

    # Standard accessor with special handling for +age+,
    # +availability+, +datetime+, +location+, +notes+, +status+,
    # +title+, and +uid+
    #
    # @param k [String] Key/property name
    def [](k)
      case k
      when 'age'                # pseudo-property
        @self['sdate'].year - @self['edate'].year

      when 'availability'       # Integer -> String
        EventKit::EKEventAvailability.select { |_k, v| v == @self['availability'] }.keys

      when 'datetime'           # date[ at time[ - time]]
        unless $opts[:sd] || $opts[:days] == 1
          t = @self['sdate'].to_s
          t += ' at ' unless @self['all_day'].positive?
        end

        unless (@self['all_day'] && @self['all_day'].positive?) || @self['placeholder']
          t ||= ''
          t += "#{@self['sctime'].strftime($opts[:tf])}" if @self['sctime']
          t += " - #{@self['ectime'].strftime($opts[:tf])}" unless $opts[:eed] || !@self['ectime'] || @self['duration'].zero?
        end
        t

      when 'location'           # location[ address]
        (@self['location'])? [ @self['location'], @self['address'] ].join(' ').chop : nil

      when 'notes'              # \n -> :nnr
        (@self['notes'])? @self['notes'].strip.gsub("\n", $opts[:nnr]) : nil

      when 'sday'               # pseudo-property
        RDT.new(*@self['sdate'].to_a[0..2])

      when 'status'             # Integer -> String
        EventKit::EKEventStatus.select { |_k, v| v == @self['status'] }.keys[0]

      when 'title'              # title[ (age N)]
        @self['title'] + ((@self['calendar'] == 'Birthdays')? " (age #{self['age']})" : '')

      when 'uid'                # for icalBuddy
        @self['UUID']

      else @self[k]
      end
    end

    # @overload initialize(obj)
    #  @param obj [SQLite3::ResultSet::HashWithTypesAndFields]
    #
    # @overload initialize(obj<DateTime>)
    #  Create a placeholder event for days with no events when using --sed
    #  @param obj [DateTime]
    def initialize(obj)
      # Placeholder for days with no events
      return @self = {
        $opts[:sep] => obj,
        'sdate' => obj,
        'placeholder' => true,
        'title' => 'Nothing.',
      } if DateTime === obj

      @self = {}
      obj.each_key { |k| @self[k] = obj[k] }

      # Convert JSON arrays to Arrays
      @self['attendees'] = JSON.parse(obj['attendees'])
      @self['xdate'] = JSON.parse(obj['xdate']).map do |k|
        RDT.from_itime(k) if k
      end

      # Convert iCal dates to normal dates
      obj.keys.select { |i| i.end_with? '_date' }.each do |k|
        next unless obj[k]

        begin
          zone = Timezone.fetch(obj['start_tz'])
        rescue Timezone::Error::InvalidZone
          zone = '+00:00'
        end

        # Save as seconds, Time, RDT
        ctime = obj[k] + ITIME
        @self["#{k[0]}seconds"] = ctime
        @self["#{k[0]}ctime"] = Time.at(ctime)
        @self["#{k[0]}date"] = RDT.from_time(Time.at(ctime, in: zone))
      end

      # Type of calendar event is from
      obj['type'] = EventKit::EKSourceType.find_index { |i| i[:name] == 'Subscribed' } if obj['subcal_url']
      type = EventKit::EKSourceType[obj['type']]

      @self['symbolic_color_name'] ||= @self['color']
      @self['type'] = type[:name]
    end

    # Check non-recurring events
    #
    # @return [Array<Event>]
    #   If an event spans multiple days, the return value will contain
    #   a unique {Event} for each day that falls within our window
    def non_recurring
      events = []

      nDays = (self['duration'] / 86_400).to_i

      # Sanity checks
      return events if nDays > 100_000

      # If multi-day, each (unique) day needs to end at 23:59:59
      self['edate'] = RDT.new(*@self['sdate'].to_a[0..2] + [ 23, 59, 59 ]) if nDays.positive?

      # Repeat for multi-day events
      (nDays + 1).times do |i|
        break if self['sdate'] > $opts[:to]

        if in_window?(self['sdate'], self['edate'])
          self['daynum'] = i + 1 if nDays.positive?
          events.push(clone)
        end

        self['sdate'] += 1
        self['edate'] += 1
      end

      events
    end

    # Check recurring events
    #
    # @return [Array<Event>]
    #   All occurrences of a recurring event that are within our window
    def recurring
      stop = [ $opts[:to], (self['rdate'] || $opts[:to]) ].min
      events = []
      count = 1

      # See if event ends before we start
      return events if $opts[:from] > stop

      # Get changes to series
      changes = [ { orig_date: -1 } ]
      changes += $rows.select { |r| r['orig_item_id'] == self['ROWID'] }

      while self['sdate'] <= stop
        # count
        break if self['count'].positive? && count > self['count']

        count += 1

        # Handle specifier
        o = []
        o.push(self) unless self['specifier'] && self['specifier'].length.positive?
        o += occurrences if self['specifier'] && self['specifier'].length.positive?

        # Check for changes
        o.each do |occurrence|
          skip = false

          changes[1..].each do |change|
            codate = Time.at(change['orig_date'] + ITIME, in: '+00:00').to_a[3..5].reverse
            odate = occurrence['sdate'].ymd

            skip = true if codate == odate
          end

          events.push(clone(occurrence)) if in_window?(occurrence['sdate'], occurrence['edate']) && !skip
        end

        # Handle frequency and interval
        apply_frequency! if self['frequency'] && self['interval']
      end

      # Remove exceptions
      events.delete_if { |event| event['xdate'].any?(event['sdate']) }

      events.uniq { |e| e['sdate'] }
    end

    private

    # @!visibility public

    # Deep clone an object
    #
    # @param obj [Object]
    # @return [Object] a deep clone of obj
    def clone(obj = self)
      Marshal.load(Marshal.dump(obj))
    end

    # Get next occurrences of a recurring event given a specifier
    #
    # @return [Array<ICalPal::Event>]
    def occurrences
      o = []

      dow = DOW.keys
      dom = []
      moy = 1..12
      nth = nil

      # Deconstruct specifier
      self['specifier'].split(';').each do |k|
        j = k.split('=')

        # D=Day of the week, M=Day of the month, O=Month of the year, S=Nth
        case j[0]
        when 'D' then dow = j[1].split(',')
        when 'M' then dom = j[1].split(',')
        when 'O' then moy = j[1].split(',')
        when 'S' then nth = j[1].to_i
        else $log.warn("Unknown specifier: #{k}")
        end
      end

      # Build array of DOWs
      dows = []
      dow.each do |d|
        dows.push(DOW[d[-2..].to_sym])
        nth = d[0..-3].to_i if [ '+', '-' ].include? d[0]
      end

      # Months of the year (O)
      moy.each do |mo|
        m = mo.to_i

        # Set dates to the first of <m>
        nsdate = RDT.new(self['sdate'].year, m, 1, self['sdate'].hour, self['sdate'].minute, self['sdate'].second)
        nedate = RDT.new(self['edate'].year, m, 1, self['edate'].hour, self['edate'].minute, self['edate'].second)

        # ...but not in the past
        nsdate >>= 12 if nsdate.month < m
        nedate >>= 12 if nedate.month < m

        next if nsdate > $opts[:to]
        next if ((nedate >> 1) - 1) < $opts[:from]

        c = clone

        # Days of the month (M)
        dom.each do |day|
          c['sdate'] = RDT.new(nsdate.year, nsdate.month, day.to_i)
          c['edate'] = RDT.new(nedate.year, nedate.month, day.to_i)

          o.push(clone(c)) if in_window?(c['sdate'], c['edate'])
        end

        # Days of the week (D)
        dows.each do |day|
          if nth
            c['sdate'] = ICalPal.nth(nth, day, nsdate)
            c['edate'] = ICalPal.nth(nth, day, nedate)
          else
            diff = day - c['sdate'].wday
            diff += 7 if diff.negative?

            c['sdate'] += diff
            c['edate'] += diff
          end

          o.push(clone(c)) if in_window?(c['sdate'], c['edate'])
        end
      end

      o
    end

    # Apply frequency and interval
    def apply_frequency!
      # Leave edate alone for birthdays to compute age
      dates = [ 'sdate' ]
      dates << 'edate' unless self['calendar'].include?('Birthday')

      dates.each do |d|
        case EventKit::EKRecurrenceFrequency[self['frequency'] - 1]
        when 'daily'   then self[d] +=  self['interval']
        when 'weekly'  then self[d] +=  self['interval'] * 7
        when 'monthly' then self[d] >>= self['interval']
        when 'yearly'  then self[d] >>= self['interval'] * 12
        else $log.error("Unknown frequency: #{self['frequency']}")
        end
      end
    end

    # Check if an event starts or ends between from and to, or if it's
    # running now (for eventsNow)
    #
    # @param s [RDT] Event start
    # @param e [RDT] Event end
    # @return [Boolean]
    def in_window?(s, e)
      if $opts[:now]
        if ($now >= s && $now < e)
          $log.debug("now: #{s} to #{e} vs. #{$now}")
          true
        else
          $log.debug("not now: #{s} to #{e} vs. #{$now}")
          false
        end
      elsif ([ s, e ].max >= $opts[:from] && s < $opts[:to])
        $log.debug("in window: #{s} to #{e} vs. #{$opts[:from]} to #{$opts[:to]}")
        true
      else
        $log.debug("not in window: #{s} to #{e} vs. #{$opts[:from]} to #{$opts[:to]}")
        false
      end
    end

    QUERY = <<~SQL.freeze
SELECT DISTINCT

Store.name AS account,
Store.type,

Calendar.color,
Calendar.title AS calendar,
Calendar.subcal_url,
Calendar.symbolic_color_name,

CAST(CalendarItem.end_date AS INT) AS end_date,
CAST(CalendarItem.orig_date AS INT) AS orig_date,
CAST(CalendarItem.start_date AS INT) AS start_date,
CAST(CalendarItem.end_date - CalendarItem.start_date AS INT) AS duration,
CalendarItem.all_day,
CalendarItem.availability,
CalendarItem.conference_url_detected,
CalendarItem.description AS notes,
CalendarItem.has_recurrences,
CalendarItem.invitation_status,
CalendarItem.orig_item_id,
CalendarItem.rowid,
CalendarItem.start_tz,
CalendarItem.status,
CalendarItem.summary AS title,
CalendarItem.unique_identifier,
CalendarItem.url,
CalendarItem.uuid,

json_group_array(DISTINCT CAST(ExceptionDate.date AS INT)) AS xdate,

json_group_array(DISTINCT Identity.display_name) AS attendees,

Location.address AS address,
Location.title AS location,

Recurrence.count,
CAST(Recurrence.end_date AS INT) AS rend_date,
Recurrence.frequency,
Recurrence.interval,
Recurrence.specifier,

min(Alarm.trigger_interval) AS trigger_interval

FROM Store

JOIN Calendar ON Calendar.store_id = Store.rowid
JOIN CalendarItem ON CalendarItem.calendar_id = Calendar.rowid

LEFT OUTER JOIN Location ON Location.rowid = CalendarItem.location_id
LEFT OUTER JOIN Recurrence ON Recurrence.owner_id = CalendarItem.rowid
LEFT OUTER JOIN ExceptionDate ON ExceptionDate.owner_id = CalendarItem.rowid
LEFT OUTER JOIN Alarm ON Alarm.calendaritem_owner_id = CalendarItem.rowid
LEFT OUTER JOIN Participant ON Participant.owner_id = CalendarItem.rowid
LEFT OUTER JOIN Identity ON Identity.rowid = Participant.identity_id

WHERE Store.disabled IS NOT 1

GROUP BY CalendarItem.rowid

ORDER BY CalendarItem.unique_identifier
SQL

  end
end
