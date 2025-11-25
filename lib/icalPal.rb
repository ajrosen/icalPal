%w[ EventKit ToICalPal calendar event rdt reminder store ].each { |l| rr l }

# Encapsulate the _Store_ (accounts), _Calendar_ and _CalendarItem_
# tables of a Calendar database, and _Reminders_ (tasks) of a
# Reminders database
module ICalPal
  attr_reader :self

  # Dynamic instantiation of our classes based on the command being
  # run
  #
  # @param klass [String] One of +accounts+, +calendars+, +events+, or +tasks+
  # @return [Class] The subclass of ICalPal
  def self.call(klass)
    case klass
    when 'accounts' then Store
    when 'calendars' then Calendar
    when 'events' then Event
    when 'tasks' then Reminder
    else
      $log.fatal("Unknown class: #{klass}")
      exit
    end
  end

  # Load data from a database
  #
  # @param db_file [String] Path to the database file
  # @param q [String] The query to run
  # @return [Array<Hash>] Array of rows returned by the query
  def self.load_data(db_file, q)
    $log.debug(q.gsub("\n", ' '))

    rows = []

    begin
      # Open the database
      $log.debug("Opening database: #{db_file}")
      db = SQLite3::Database.new(db_file, { readonly: true, results_as_hash: true })

      # Prepare the query
      stmt = db.prepare(q)

      # Check for "list" and "all" pseudo-properties
      abort(stmt.columns.sort.join(' ')) if $opts[:props].any? 'list'
      $opts[:props] = stmt.columns - $opts[:eep] if $opts[:props].any? 'all'

      # Iterate the SQLite3::ResultSet once
      stmt.execute.each { |i| rows.push(i) }
      stmt.close

      # Close the database
      db.close
      $log.debug("Closed #{db_file}")
    end

    rows
  end

  # Initialize fields common to all ICalPal classes
  #
  # @param obj [ICalPal] An +Store+, +Calendar+, +Event+, or +Reminder+
  def initialize(obj)
    @self = obj

    obj['store'] = obj['account']

    obj['type'] = EventKit::EKSourceType.find_index { |i| i[:name] == 'Subscribed' } if obj['subcal_url']
    return unless obj['type']

    type = EventKit::EKSourceType[obj['type']]

    obj['type'] = type[:name]
    obj['color'] ||= type[:color]
    obj['symbolic_color_name'] ||= type[:color]
  end

  # Create a new CSV::Row with values from +self+.  Control characters
  # are escaped to ensure they are not interpreted by the terminal.
  #
  # @param headers [Array] Key names used as the header row in a CSV::Table
  # @return [CSV::Row] The +Store+, +Calendar+, +CalendarItem+, or
  # +Reminder+ as a CSV::Row
  def to_csv(headers)
    values = headers.map do |h|
      (@self[h].respond_to?(:gsub))?
        @self[h].gsub(/([[:cntrl:]])/) { |c| c.dump[1..-2] } : @self[h]
    end

    CSV::Row.new(headers, values)
  end

  # Convert +self+ to XML
  #
  # @return [String] All fields in a simple XML format: <field>value</field>.
  # Fields with empty values return <field/>.
  def to_xml
    retval = ''
    @self.each_key { |k| retval += xmlify(k, @self[k]) }

    retval
  end

  # Get the +n+'th +dow+ in month +m+
  #
  # @param n [Integer] Integer between -4 and +4
  # @param dow [Integer] Day of the week
  # @param m [RDT] The RDT with the year and month we're searching
  # @return [RDT] The resulting day
  def self.nth(n, dow, m)
    # Get the number of days in the month by advancing to the first of
    # the next month, then going back one day
    a = [ RDT.new(m.year, m.month, 1, m.hour, m.min, m.sec, m.zone) ]
    a[1] = (a[0] >> 1) - 1

    # Reverse it if going backwards
    a.reverse! if n.negative?
    step = a[1] <=> a[0]

    j = 0
    a[0].step(a[1], step) do |i|
      j += step if dow == i.wday
      return i if j == n
    end
  end

  # Epoch + 31 years (Mon Jan  1 00:00:00 UTC 2001)
  ITIME = 978_307_200

  # Days of the week abbreviations used in recurrence rules
  #
  # <tt><i>SU, MO, TU, WE, TH, FR, SA</i></tt>
  DOW = { SU: 0, MO: 1, TU: 2, WE: 3, TH: 4, FR: 5, SA: 6 }.freeze

  # @!group Accessors
  def [](k)
    @self[k]
  end

  def []=(k, v)
    @self[k] = v
  end

  def keys
    @self.keys
  end

  def values
    @self.values
  end

  # @see Array.<=>
  #
  # If either self or other is nil, but not both, the nil object is
  # always less than
  def <=>(other)
    $sort_attrs.each do |s|
      next if self[s] == other[s]

      # nil is always less than
      return -1 if other[s].nil?
      return 1 if self[s].nil?

      return -1 if self[s] < other[s]
      return 1 if self[s] > other[s]
    end

    0
  end

  # Like inspect, but easier for humans to read
  #
  # @return [Array<String>] @self as a key=value array, sorted by key
  def dump
    @self.keys.sort.map { |k| "#{k}: #{@self[k]}" }
  end

  # @!endgroup
end
