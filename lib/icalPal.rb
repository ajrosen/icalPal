require_relative 'EventKit'
require_relative 'ToICalPal'
require_relative 'calendar'
require_relative 'event'
require_relative 'rdt'
require_relative 'reminder'
require_relative 'store'

# Encapsulate the _Store_ (accounts), _Calendar_ and _CalendarItem_
# tables of a Calendar database, and the _Reminder_ table of a
# Reminders database
module ICalPal
  attr_reader :self

  # Dynamic instantiation of our classes based on the command being
  # run
  #
  # @param klass [String] One of +accounts+, +stores+, +calendars+, +events+, or +tasks+
  # @return [Class] The subclass of ICalPal
  def self.call(klass)
    case klass
    when 'accounts' then Store
    when 'stores' then Store
    when 'calendars' then Calendar
    when 'events' then Event
    when 'tasks' then Reminder
    else
      $log.fatal("Unknown class: #{klass}")
      exit
    end
  end

  # Load data
  def self.load_data(db_file, q)
    $log.debug(q.gsub(/\n/, ' '))

    rows = []

    begin
      # Open the database
      $log.debug("Opening database: #{db_file}")
      db = SQLite3::Database.new(db_file, { readonly: true, results_as_hash: true })

      # Prepare the query
      stmt = db.prepare(q)
      abort(stmt.columns.sort.join(' ')) if $opts[:props].any? 'list'
      $opts[:props] = stmt.columns - $opts[:eep] if $opts[:props].any? 'all'

      # Iterate the SQLite3::ResultSet once
      stmt.execute.each_with_index { |i, j| rows[j] = i }
      stmt.close

      # Close the database
      db.close
      $log.debug("Closed #{db_file}")

    rescue SQLite3::BusyException => e
      $log.error("Non-fatal error closing database #{db.filename}")
      raise e

    rescue SQLite3::CantOpenException => e
      $log.debug("Can't open #{db_file}")
      raise e

    rescue SQLite3::SQLException => e
      $log.info("#{db_file}: #{e}")
      raise e

    rescue SQLite3::Exception => e
      abort("#{db_file}: #{e}")
    end

    rows
  end

  # @param obj [ICalPal] A +Store+ or +Calendar+
  def initialize(obj)
    obj['type'] = EventKit::EKSourceType.find_index { |i| i[:name] == 'Subscribed' } if obj['subcal_url']
    type = EventKit::EKSourceType[obj['type']]

    obj['store'] = obj['account']

    obj['type'] = type[:name]
    obj['color'] ||= type[:color]
    obj['symbolic_color_name'] ||= type[:color]

    @self = obj
  end

  # Create a new CSV::Row with values from +self+.  Newlines are
  # replaced with '\n' to ensure each Row is a single line of text.
  #
  # @param headers [Array] Key names used as the header row in a CSV::Table
  # @return [CSV::Row] The +Store+, +Calendar+, or +CalendarItem+ as a CSV::Row
  def to_csv(headers)
    values = []
    headers.each { |h| values.push((@self[h].respond_to?(:gsub))? @self[h].gsub(/\n/, '\n') : @self[h]) }

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

  # Convert a key/value pair to XML.  The value should be +nil+, +String+,
  # +Integer+, +Array+, or +ICalPal::RDT+
  #
  # @param key The key
  # @param value The value
  # @return [String] The key/value pair in a simple XML format
  def xmlify(key, value)
    case value
    # Nil
    when NilClass then "<#{key}/>"

    # String, Integer
    when String then "<#{key}>#{value}</#{key}>"
    when Integer then "<#{key}>#{value}</#{key}>"

    # Array
    when Array
      # Treat empty arrays as nil values
      xmlify(key, nil) if value[0].nil?

      retval = ''
      value.each { |x| retval += xmlify("#{key}0", x) }
      "<#{key}>#{retval}</#{key}>"

    # RDT
    when ICalPal::RDT then "<#{key}>#{value}</#{key}>"

    # Unknown
    else "<#{key}>#{value}</#{key}>"
    end
  end

  # Get the +n+'th +dow+ in month +m+
  #
  # @param n [Integer] Integer between -4 and +4
  # @param dow [Array] Days of the week
  # @param m [RDT] The RDT with the year and month we're searching
  # @return [RDT] The resulting day
  def self.nth(n, dow, m)
    # Get the number of days in the month
    a = [ ICalPal::RDT.new(m.year, m.month, 1) ] # First of this month
    a[1] = (a[0] >> 1) - 1                       # First of next month, minus 1 day

    # Reverse it if going backwards
    a.reverse! if n.negative?
    step = a[1] <=> a[0]

    j = 0
    a[0].step(a[1], step) do |i|
      j += step if dow.any?(i.wday)
      return i if j == n
    end
  end

  # Epoch + 31 years
  ITIME = 978_307_200

  # Days of the week abbreviations used in recurrence rules
  #
  # <tt><i>SU, MO, TU, WE, TH, FR, SA</i></tt>
  DOW = { 'SU': 0, 'MO': 1, 'TU': 2, 'WE': 3, 'TH': 4, 'FR': 5, 'SA': 6 }.freeze

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
  # @!endgroup
end
