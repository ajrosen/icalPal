require 'optparse'

require_relative 'defaults'

module ICalPal
  # Handle program options from all sources:
  #
  # * Defaults
  # * Environment variables
  # * Configuration file
  # * Command-line arguments
  #
  # Many options are intentionally copied from
  # icalBuddy[https://github.com/ali-rantakari/icalBuddy].  Note that
  # icalPal requires two hyphens for all options, except single-letter
  # options which require a single hyphen.
  #
  # Options can be abbreviated as long as they are unique.
  class Options
    # Define the OptionParser
    def initialize
      # prologue
      @op = OptionParser.new
      @op.summary_width = 23
      @op.banner += " [-c] COMMAND"
      @op.version = '1.1.17.issue9'

      @op.accept(ICalPal::RDT) { |s| ICalPal::RDT.conv(s) }

      # head
      @op.on("\nCOMMAND must be one of the following:\n\n")

      @op.on("%s%s %sPrint events" % pad('events'))
      @op.on("%s%s %sPrint calendars" % pad('calendars'))
      @op.on("%s%s %sPrint accounts" % pad('accounts'))

      @op.separator('')
      @op.on("%s%s %sPrint events occurring today" % pad('eventsToday'))
      @op.on("%s%s %sPrint events occurring between today and NUM days into the future" % pad('eventsToday+NUM'))
      @op.on("%s%s %sPrint events occurring at present time" % pad('eventsNow'))

      # global
      @op.separator("\nGlobal options:\n\n")

      @op.on('-c=COMMAND', '--cmd=COMMAND', COMMANDS, 'Command to run')
      @op.on('--db=DB', 'Use DB file instead of Calendar')
      @op.on('--cf=FILE', "Set config file path (default: #{$defaults[:common][:cf]})")
      @op.on('-o', '--output=FORMAT', OUTFORMATS,
            "Print as FORMAT (default: #{$defaults[:common][:output]})", "[#{OUTFORMATS.join(', ')}]")

      # include/exclude
      @op.separator("\nIncluding/excluding calendars:\n\n")

      @op.on('--is=ACCOUNTS', Array, 'List of accounts to include')
      @op.on('--es=ACCOUNTS', Array, 'List of accounts to exclude')

      @op.separator('')
      @op.on('--it=TYPES', Array, 'List of calendar types to include')
      @op.on('--et=TYPES', Array, 'List of calendar types to exclude',
            "[#{EventKit::EKSourceType.map { |i| i[:name] }.join(', ') }]")

      @op.separator('')
      @op.on('--ic=CALENDARS', Array, 'List of calendars to include')
      @op.on('--ec=CALENDARS', Array, 'List of calendars to exclude')

      # dates
      @op.separator("\nChoosing dates:\n\n")

      @op.on('--from=DATE', ICalPal::RDT, 'List events starting on or after DATE')
      @op.on('--to=DATE', ICalPal::RDT, 'List events starting on or before DATE',
            'DATE can be yesterday, today, tomorrow, +N, -N, or anything accepted by DateTime.parse()',
            'See https://ruby-doc.org/stdlib-2.6.1/libdoc/date/rdoc/DateTime.html#method-c-parse')
      @op.separator('')
      @op.on('-n', 'Include only events from now on')
      @op.on('--days=N',  OptionParser::DecimalInteger,
            'Show N days of events, including start date')
      @op.on('--sed', 'Show empty dates with --sd')
      @op.on('--ia', 'Include only all-day events')
      @op.on('--ea', 'Exclude all-day events')

      # properties
      @op.separator("\nChoose properties to include in the output:\n\n")

      @op.on('--iep=PROPERTIES', Array, 'List of properties to include')
      @op.on('--eep=PROPERTIES', Array, 'List of properties to exclude')
      @op.on('--aep=PROPERTIES', Array, 'List of properties to include in addition to the default list')
      @op.separator('')
      # @op.on('--itp=PROPERTIES', Array, 'List of task properties to include')
      # @op.on('--etp=PROPERTIES', Array, 'List of task properties to exclude')
      # @op.on('--atp=PROPERTIES', Array, 'List of task properties to include in addition to the default list')
      # @op.separator('')

      @op.on('--uid', 'Show event UIDs')
      @op.on('--eed', 'Exclude end datetimes')

      @op.separator('')
      @op.on('--nc', 'No calendar names')
      @op.on('--npn', 'No property names')
      @op.on('--nrd', 'No relative dates')

      @op.separator('')
      @op.separator(@op.summary_indent + 'Properties are listed in the order specified')
      @op.separator('')
      @op.separator(@op.summary_indent +
                   "Use 'all' for PROPERTIES to include all available properties (except any listed in --eep)")
      @op.separator(@op.summary_indent +
                   "Use 'list' for PROPERTIES to list all available properties and exit")

      # formatting
      @op.separator("\nFormatting the output:\n\n")

      @op.on('--li=N', OptionParser::DecimalInteger, 'Show at most N items (default: 0 for no limit)')

      @op.separator('')
      @op.on('--sc', 'Separate by calendar')
      @op.on('--sd', 'Separate by date')
      # @op.on('--sp', 'Separate by priority')
      # @op.on('--sta', 'Sort tasks by due date (ascending)')
      # @op.on('--std', 'Sort tasks by due date (descending)')
      # @op.separator('')
      @op.on('--sep=PROPERTY', 'Separate by PROPERTY')
      @op.separator('')
      @op.on('--sort=PROPERTY', 'Sort by PROPERTY')
      @op.on('-r', '--reverse', 'Sort in reverse')

      @op.separator('')
      @op.on('--ps=SEPARATORS', Array, 'List of property separators')
      @op.on('--ss=SEPARATOR', String, 'Set section separator')

      @op.separator('')
      @op.on('--df=FORMAT', String, 'Set date format')
      @op.on('--tf=FORMAT', String, 'Set time format',
            'See https://ruby-doc.org/stdlib-2.6.1/libdoc/date/rdoc/DateTime.html#method-i-strftime for details')

      @op.separator('')
      @op.on('-b', '--bullet=STRING', String, 'Use STRING for bullets')
      @op.on('--nb', 'Do not use bullets')
      @op.on('--nnr=SEPARATOR', String, 'Set replacement for newlines within notes')

      @op.separator('')
      @op.on('-f', 'Format output using standard ANSI colors')
      @op.on('--color', 'Format output using a larger color palette')

      # help
      @op.separator("\nHelp:\n\n")

      @op.on('-h', '--help', 'Show this message') { @op.abort(@op.help) }
      @op.on('-V', '-v', '--version', "Show version and exit (#{@op.version})") { @op.abort(@op.version)  }
      @op.on('-d', '--debug=LEVEL', /#{Regexp.union(Logger::SEV_LABEL[0..-2]).source}/i,
            "Set the logging level (default: #{Logger::SEV_LABEL[$defaults[:common][:debug]].downcase})",
            "[#{Logger::SEV_LABEL[0..-2].join(', ').downcase}]")

      # environment variables
      @op.on_tail("\nEnvironment variables:\n\n")

      @op.on_tail("%s%s %sAdditional arguments" % pad('ICALPAL'))
      @op.on_tail("%s%s %sAdditional arguments from a file" % pad('ICALPAL_CONFIG'))
      @op.on_tail("%s%s %s(default: #{$defaults[:common][:cf]})" % pad(''))
    end

    # Parse options from the CLI and merge them with other sources
    #
    # @return [Hash] All options loaded from defaults, environment
    #  variables, configuration file, and the command line
    def parse_options
      begin
        cli = {}
        env = {}
        cf = {}

        # Load from CLI, environment, configuration file
        @op.parse!(into: cli)
        @op.parse!(ENV['ICALPAL'].split, into: env) rescue nil
        cli[:cf] ||= ENV['ICALPAL_CONFIG'] || $defaults[:common][:cf]
        @op.parse!(File.read(File.expand_path(cli[:cf])).split, into: cf) rescue nil

        cli[:cmd] ||= @op.default_argv[0]
        cli[:cmd] ||= env[:cmd] if env[:cmd]
        cli[:cmd] ||= cf[:cmd] if cf[:cmd]
        cli[:cmd] = 'stores' if cli[:cmd] == 'accounts'

        # Parse eventsNow and eventsToday commands
        cli[:cmd].match('events(Now|Today)(\+[0-9]+)?') do |m|
          cli[:n] = true if m[1] == 'Now'
          cli[:days] = (m[1] == 'Today')? m[2].to_i + 1 : 1

          cli[:from] = $today
          cli[:to] = $today + cli[:days]
          cli[:days] = Integer(cli[:to] - cli[:from])

          cli[:cmd] = 'events'
        end if cli[:cmd]

        # Must have a valid command
        raise(OptionParser::MissingArgument, 'COMMAND is required') unless cli[:cmd]
        raise(OptionParser::InvalidArgument, "Unknown COMMAND #{cli[:cmd]}") unless (COMMANDS.any? cli[:cmd])

        # Merge options
        opts = $defaults[:common]
          .merge($defaults[cli[:cmd].to_sym])
          .merge(cf)
          .merge(env)
          .merge(cli)

        # All kids love log!
        $log.level = opts[:debug]

        # From the Department of Redundancy Department
        opts[:props] = (opts[:iep] + opts[:aep] - opts[:eep]).uniq

        # From, to, days
        if opts[:from]
          opts[:to] += 1 if opts[:to]
          opts[:to] ||= opts[:from] + 1 if opts[:from]
          opts[:to] = opts[:from] + opts[:days] if opts[:days]
          opts[:days] ||= Integer(opts[:to] - opts[:from])
          opts[:from] = $now if opts[:n]
        end

        # Colors
        opts[:palette] = 8 if opts[:f]
        opts[:palette] = 24 if opts[:color]

        # Sections
        unless opts[:sep]
          opts[:sep] = 'calendar' if opts[:sc]
          opts[:sep] = 'sday' if opts[:sd]
          opts[:sep] = 'priority' if opts[:sp]
        end
        opts[:nc] = true if opts[:sc]

        # Sanity checks
        raise(OptionParser::InvalidArgument, '--li cannot be negative') if opts[:li].negative?
        raise(OptionParser::InvalidOption, 'Start date must be before end date') if opts[:from] && opts[:from] > opts[:to]
        raise(OptionParser::MissingArgument, 'No properties to display') if opts[:props].empty?

        # Open the database here so we can catch errors and print the help message
        $log.debug("Opening database: #{opts[:db]}")
        $db = SQLite3::Database.new(opts[:db], { readonly: true, results_as_hash: true })
        $db.prepare('SELECT 1 FROM Calendar LIMIT 1').close

      rescue SQLite3::SQLException => e
        @op.abort("#{opts[:db]} is not a Calendar database")

      rescue SQLite3::Exception => e
        @op.abort("#{opts[:db]}: #{e}")

      rescue StandardError => e
        @op.abort("#{e}\n\n#{@op.help}\n#{e}")
      end

      opts.sort.to_h
    end

    # Commands that can be run
    COMMANDS = %w{events eventsToday eventsNow calendars accounts stores}

    # Supported output formats
    OUTFORMATS = %w{ansi csv default hash html json md rdoc toc yaml remind}

    private

    # Pad non-options to align with options
    #
    # @param t [String] Text on the left side
    # @return [String] Text indented by summary_indent, and padded according to summary_width
    def pad(t)
      [ @op.summary_indent, t, " " * (@op.summary_width - t.length) ]
    end
  end
end
