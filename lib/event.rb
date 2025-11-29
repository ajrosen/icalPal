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

      @self['sctime'] = Time.at(@self['sdate'].to_i) if k == 'sdate'
      @self['ectime'] = Time.at(@self['edate'].to_i) if k == 'edate'
    end

    # Standard accessor with special handling for +age+,
    # +availability+, +datetime+, +location+, +notes+, +sday+,
    # +status+, +uid+, and +event+/+name+/+title+
    #
    # @param k [String] Key/property name
    def [](k)
      case k
      when 'age'                # pseudo-property
        @self['sdate'].year - Time.at(@self['start_date'] + ITIME).year

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
        @self['sdate'].day_start(0)

      when 'status'             # Integer -> String
        EventKit::EKEventStatus.select { |_k, v| v == @self['status'] }.keys[0]

      when 'uid'                # for icalBuddy
        @self['UUID']

      when 'event', 'name', 'title' # title[ (age N)]
        @self['title'] + ((@self['calendar'] == 'Birthdays')? " (age #{self['age']})" : '')

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
      } if $opts[:sed] && obj.is_a?(DateTime)

      super

      # Convert JSON arrays to Arrays
      @self['attendees'] = JSON.parse(obj['attendees'])
      @self['xdate'] = JSON.parse(obj['xdate']).map do |k|
        RDT.from_itime(Time.at(k, in: '+00:00')) if k
      end

      # Convert iCal dates to normal dates
      obj.keys.select { |i| i.end_with? '_date' }.each do |k|
        next unless obj[k]

        zone = nil
        zone = '+00:00' if obj['all_day'].positive?

        # Save as seconds, Time, RDT
        ctime = obj[k] + ITIME
        ctime -= Time.at(ctime).utc_offset if obj["#{k.split('_')[0]}_tz"] == '_float'
        ttime = Time.at(ctime, in: zone)

        @self["#{k[0]}seconds"] = ctime
        @self["#{k[0]}ctime"] = ttime
        @self["#{k[0]}date"] = RDT.from_time(ttime)
      end

      @self.delete('unique_identifier')
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
      self['edate'] = RDT.new(*@self['sdate'].to_a[0..2] + [ 23, 59, 59 ], @self['sdate'].zone) if nDays.positive?

      # Repeat for multi-day events
      (nDays + 1).times do |i|
        break unless $opts[:now] || @self['sdate'] <= $opts[:to]

        if in_window?(@self['sdate'], @self['edate'])
          @self['daynum'] = i + 1 if nDays.positive?
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

      while @self['sdate'] <= stop
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

          events.push(clone(occurrence)) if !skip && in_window?(occurrence['sdate'], occurrence['edate'])
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
        nsdate = RDT.new(@self['sdate'].year, m, 1, @self['sdate'].hour, @self['sdate'].min, @self['sdate'].sec, @self['sdate'].zone)
        nedate = RDT.new(@self['edate'].year, m, 1, @self['edate'].hour, @self['edate'].min, @self['edate'].sec, @self['edate'].zone)

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
            %w[ sdate edate ].each do |d|
              diff = day - c['sdate'].wday
              diff += 7 if diff.negative?

              t1 = Time.at(c[d].to_time)
              t2 = Time.at(t1.to_i + (diff * 86_400))
              t2 += (t1.gmt_offset - t2.gmt_offset)

              c[d] = RDT.from_time(t2)
            end
          end

          o.push(clone(c)) if in_window?(c['sdate'], c['edate'])
        end
      end

      o
    end

    # Apply frequency and interval
    def apply_frequency!
      %w[ sdate edate ].each do |d|
        case EventKit::EKRecurrenceFrequency[self['frequency'] - 1]
        when 'daily'   then nd = self[d] + self['interval']
        when 'weekly'  then nd = self[d] + (self['interval'] * 7)
        when 'monthly' then nd = self[d] >> self['interval']
        when 'yearly'  then nd = self[d] >> (self['interval'] * 12)
        else $log.error("Unknown frequency: #{self['frequency']}")
        end

        # Create a new Time object in case we crossed a daylight saving change
        t = Time.parse("#{nd.year}-#{nd.month}-#{nd.day} #{nd.hour}:#{nd.min}:#{nd.sec}")
        self[d] = RDT.from_time(t)
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
        if $nowto_i.between?(s.to_i, e.to_i)
          $log.debug("now: #{s} to #{e} vs. #{$now}")
          true
        else
          $log.debug("not now: #{s} to #{e} vs. #{$now}")
          false
        end
      elsif (s < $opts[:to] && [ s, e ].max >= $opts[:from])
        $log.debug("#{@self['title']} in window: #{s} to #{e} vs. #{$opts[:from]} to #{$opts[:to]}")
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
CalendarItem.end_tz,
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
