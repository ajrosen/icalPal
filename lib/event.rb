require 'time'

module ICalPal
  # Class representing items from the <tt>CalendarItem</tt> table
  class Event
    include ICalPal

    # Standard accessor with special handling for +sdate+.  Setting
    # +sdate+ will also set +sday+.
    #
    # @param k [String] Key/property name
    # @param v [Object] Key/property value
    def []=(k, v)
      @self[k] = v
      @self['sday'] = ICalPal::RDT.new(*self['sdate'].to_a[0..2]) if k == 'sdate'
    end

    # Standard accessor with special handling for +age+,
    # +availability+, +datetime+, +location+, +notes+, +status+,
    # +title+, and +uid+
    #
    # @param k [String] Key/property name
    def [](k)
      case k
      when 'age' then           # pseudo-property
        @self['sdate'].year - @self['edate'].year

      when 'availability' then  # Integer -> String
        EventKit::EKEventAvailability.select { |k, v| v == @self['availability'] }.keys

      when 'datetime' then      # date[ at time[ - time]]
        unless $opts[:sd] || $opts[:days] == 1
          t = @self['sdate'].to_s
          t += ' at ' unless @self['all_day'].positive?
        end

        unless @self['all_day'] && @self['all_day'].positive? || @self['placeholder']
          t ||= ''
          t += "#{@self['sdate'].strftime($opts[:tf])}" if @self['sdate']
          t += " - #{@self['edate'].strftime($opts[:tf])}" unless $opts[:eed] || !@self['edate']
        end
        t

      when 'location' then      # location[ address]
        @self['location']? [ @self['location'], @self['address'] ].join(' ').chop : nil

      when 'notes' then         # \n -> :nnr
        @self['notes']? @self['notes'].strip.gsub(/\n/, $opts[:nnr]) : nil

      when 'sday' then        # pseudo-property
        ICalPal::RDT.new(*@self['sdate'].to_a[0..2])

      when 'status' then        # Integer -> String
        EventKit::EKEventStatus.select { |k, v| v == @self['status'] }.keys[0]

      when 'title' then         # title[ (age N)]
        @self['title'] + ((@self['calendar'] == 'Birthdays')? " (age #{self['age']})" : "")

      when 'uid' then           # for icalBuddy
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
      obj.keys.each { |k| @self[k] = obj[k] }

      # Convert JSON arrays to Arrays
      @self['attendees'] = JSON.parse(obj['attendees'])
      @self['xdate'] = JSON.parse(obj['xdate']).map do |k|
        k = RDT.new(*Time.at(k + ITIME).to_a.reverse[4..]) if k
      end

      # Convert iCal dates to normal dates
      obj.keys.select { |i| i.end_with? '_date' }.each do |k|
        t = Time.at(obj[k] + ITIME) if obj[k]
        @self["#{k[0]}date"] = RDT.new(*t.to_a.reverse[4..], t.zone) if t
      end

      if @self['start_tz'] == '_float'
        tzoffset = Time.zone_offset($now.zone())

        @self['sdate'] = RDT.new(*(@self['sdate'].to_time - tzoffset).to_a.reverse[4..], $now.zone)
        @self['edate'] = RDT.new(*(@self['edate'].to_time - tzoffset).to_a.reverse[4..], $now.zone)
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

      nDays = (self['duration'] / 86400).to_i

      # Sanity checks
      return events if nDays > 100000

      # Repeat for multi-day events
      (nDays + 1).times do |i|
        break if self['sdate'] > $opts[:to]

        $log.debug("multi-day event #{i + 1}") if (i > 0)

        self['daynum'] = i + 1
        events.push(clone) if in_window?(self['sdate'])

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

      # See if event ends before we start
      if stop < $opts[:from] then
        $log.debug("#{stop} < #{$opts[:from]}")
        return(Array.new)
      end

      # Get changes to series
      changes = [ { 'orig_date' => -1 } ]
      changes += $rows.select { |r| r['orig_item_id'] == self['ROWID'] }

      events = []
      count = 1

      while self['sdate'] <= stop
        # count
        break if self['count'].positive? and count > self['count']
        count += 1

        # Handle specifier or clone self
        if self['specifier'] and self['specifier'].length.positive?
          occurrences = get_occurrences(changes)
        else
          occurrences = [ clone ]
        end

        # Check for changes
        occurrences.each do |occurrence|
          changes.each do |change|
            next if change['orig_date'] == self['sdate'].to_i - ITIME
            events.push(occurrence) if in_window?(occurrence['sdate'], occurrence['edate'])
          end
        end

        break if self['specifier']
        apply_frequency!
      end

      # Remove exceptions
      events.delete_if { |event| event['xdate'].any?(event['sdate']) }

      return(events)
    end

    private

    # @!visibility public

    # @return a deep clone of self
    def clone()
      Marshal.load(Marshal.dump(self))
    end

    # Get next occurences of a recurring event from a specifier
    #
    # @param changes [Array] Recurrence changes for the event
    # @return [Array<IcalPal::Event>]
    def get_occurrences(changes)
      occurrences = []

      dow = DOW.keys
      dom = [ nil ]
      moy = 1..12
      nth = nil

      specifier = self['specifier']? self['specifier'] : []

      # Deconstruct specifier
      specifier.split(';').each do |k|
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
      dows = [ nil ]
      dow.each { |d| dows.push(DOW[d[-2..-1].to_sym]) }

      # Months of the year (O)
      moy.each do |m|
        next unless m

        nsdate = RDT.new(self['sdate'].year, m.to_i, 1)
        nedate = RDT.new(self['edate'].year, m.to_i, 1)

        # Days of the month (M)
        dom.each do |x|
          next unless x

          self['sdate'] = RDT.new(nsdate.year, nsdate.month, x.to_i)
          self['edate'] = RDT.new(nedate.year, nedate.month, x.to_i)
          occurrences.push(clone)
        end

        # Days of the week (D)
        if nth
          self['sdate'] = ICalPal.nth(nth, dows, nsdate)
          self['edate'] = ICalPal.nth(nth, dows, nedate)
          occurrences.push(clone)
        else
          if dows[0]
            self['sdate'] = RDT.new(nsdate.year, m.to_i, nsdate.wday)
            self['edate'] = RDT.new(nedate.year, m.to_i, nedate.wday)
            occurrences.push(clone)
          end
        end
      end

      return(occurrences)
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
      end if self['frequency'] && self['interval']
    end

    # Check if an event starts or ends between from and to, or if it's
    # running now (for -n)
    #
    # @param s [RDT] Event start
    # @param e [RDT] Event end
    # @return [Boolean]
    def in_window?(s, e = s)
      if $opts[:n] then
        if ($now >= s && $now < e) then
          $log.debug("now: #{s} to #{e} vs. #{$now}")
          return(true)
        else
          $log.debug("not now: #{s} to #{e} vs. #{$now}")
          return(false)
        end
      else
        if ([ s, e ].max >= $opts[:from] && s < $opts[:to]) then
          $log.debug("in window: #{s} to #{e} vs. #{$opts[:from]} to #{$opts[:to]}")
          return(true)
        else
          $log.debug("not in window: #{s} to #{e} vs. #{$opts[:from]} to #{$opts[:to]}")
          return(false)
        end
      end
    end

    QUERY = <<~SQL
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
