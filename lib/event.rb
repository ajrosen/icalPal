module ICalPal
  # Class representing items from the <tt>CalendarItem</tt> table
  class Event
    include ICalPal

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

        unless @self['all_day'] && @self['all_day'].positive?
          t ||= ''
          t += "#{@self['sdate'].strftime($opts[:tf])}" if @self['sdate']
          t += " - #{@self['edate'].strftime($opts[:tf])}" unless $opts[:eed] || !@self['edate']
        end
        t

      when 'location' then      # location[ address]
        @self['location']? [ @self['location'], @self['address'] ].join(' ').chop : nil

      when 'notes' then         # \n -> :nnr
        @self['notes']? @self['notes'].strip.gsub(/\n/, $opts[:nnr]) : nil

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

      obj['type'] = EventKit::EKSourceType.find_index { |i| i[:name] == 'Subscribed' } if obj['subcal_url']
      type = EventKit::EKSourceType[obj['type']]

      @self['sdate'] = @self['sdate'].new_offset(0) if @self['start_tz'] == '_float'
      @self['symbolic_color_name'] ||= @self['color']
      @self['type'] = type[:name]
    end

    # Check non-recurring events
    #
    # @return [Array<Event>]
    #   If an event spans multiple days, the return value will contain
    #   a unique {Event} for each day that falls within our window
    def non_recurring
      retval = []

      # Repeat for multi-day events
      ((self['duration'] / 86400).to_i + 1).times do |i|
        self['daynum'] = i + 1
        retval.push(clone) if in_window?(self['sdate'])
        self['sdate'] += 1
        self['edate'] += 1
      end

      retval
    end

    # Check recurring events
    #
    # @return [Array<Event>]
    #   All occurrences of a recurring event that are within our window
    def recurring
      retval = []

      # See if event ends before we start
      stop = [ $opts[:to], (self['rdate'] || $opts[:to]) ].min
      return(retval) if stop < $opts[:from]

      # Get changes to series
      changes = $rows.select { |r| r['orig_item_id'] == self['ROWID'] }

      i = 1
      while self['sdate'] <= stop
        unless @self['xdate'].any?(@self['sdate']) # Exceptions?
          o = get_occurrences(changes)
          o.each { |r| retval.push(r) if in_window?(r['sdate'], r['edate']) }

          i += 1
          return(retval) if self['count'].positive? && i > self['count']
        end

        apply_frequency!
      end

      retval
    end

    private

    # @!visibility public

    # @return a deep clone of self
    def clone()
      self['stime'] = self['sdate'].to_i
      self['etime'] = self['edate'].to_i
      Marshal.load(Marshal.dump(self))
    end

    # Get next occurences of a recurring event
    #
    # @param changes [Array] Recurrence changes for the event
    # @return [Array<IcalPal::Event>]
    def get_occurrences(changes)
      ndate = self['sdate']
      odays = []
      retval = []

      # Deconstruct specifier(s)
      if self['specifier']
        self['specifier'].split(';').each do |k|
          j = k.split('=')

          # M=Day of the month, O=Month of the year, S=Nth
          case j[0]
          when 'M' then ndate = RDT.new(ndate.year, ndate.month, j[1].to_i)
          when 'O' then ndate = RDT.new(ndate.year, j[1].to_i, ndate.day)
          when 'S' then @self['specifier'].sub!(/D=0/, "D=+#{j[1].to_i}")
          end
        end

        # D=Day of the week
        self['specifier'].split(';').each do |k|
          j = k.split('=')

          odays = j[1].split(',') if j[0] == 'D'
        end
      end

      # Deconstruct occurence day(s)
      odays.each do |n|
        dow = DOW[n[-2..-1].to_sym]
        ndate += 1 until ndate.wday == dow
        ndate = ICalPal.nth(Integer(n[0..1]), n[-2..-1], ndate) unless (n[0] == '0')

        # Check for changes
        changes.detect(
          proc {
            self['sdate'] = RDT.new(*ndate.to_a[0..2], *self['sdate'].to_a[3..])
            self['edate'] = RDT.new(*ndate.to_a[0..2], *self['edate'].to_a[3..])
            retval.push(clone)
          }) { |i| @self['sdate'].to_i == i['orig_date'] + ITIME }
      end

      # Check for changes
      changes.detect(
        proc {
          retval.push(clone)
        }) { |i| @self['sdate'].to_i == i['orig_date'] + ITIME } unless retval.count.positive?

      retval
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
      $opts[:n]?
        ($now >= s && $now < e) :
        ([ s, e ].max >= $opts[:from] && s < $opts[:to])
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
