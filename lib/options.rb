# rubocop: disable Style/FormatString, Style/FormatStringToken

autoload(:OptionParser, 'optparse')

require_relative 'version'

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
  # icalpal requires two hyphens for all options, except single-letter
  # options which require a single hyphen.
  #
  # Options can be abbreviated as long as they are unique.
  class Options

    # Define the OptionParser
    def initialize
      # prologue
      @op = OptionParser.new
      @op.summary_width = 23
      @op.banner += ' [-c] COMMAND'
      @op.version = VERSION

      @op.accept(RDT) { |s| RDT.conv(s) }

      # head
      @op.on_head("\nCOMMAND must be one of the following:\n\n")

      @op.on('%s%s %sPrint events' % pad('events'))
      @op.on('%s%s %sPrint tasks' % pad('tasks'))
      @op.on('%s%s %sPrint calendars' % pad('calendars'))
      @op.on('%s%s %sPrint accounts' % pad('accounts'))

      @op.separator('')
      @op.on('%s%s %sPrint events occurring today' % pad('eventsToday'))
      @op.on('%s%s %sPrint events occurring between today and NUM days into the future' % pad('eventsToday+NUM'))
      @op.on('%s%s %sPrint events occurring at present time' % pad('eventsNow'))
      @op.on('%s%s %sPrint events occurring between present time and midnight' % pad('eventsRemaining'))
      @op.on('%s%s %sPrint tasks with a due date' % pad('datedTasks'))
      @op.on('%s%s %sPrint tasks with no due date' % pad('undatedTasks'))
      @op.on('%s%s %sPrint uncompleted tasks due between the given dates' % pad('tasksDueBefore'))
      @op.separator('')
      @op.separator("#{@op.summary_indent}stores can be used instead of accounts")
      @op.separator("#{@op.summary_indent}reminders can be used instead of tasks")

      # global
      @op.separator("\nGlobal options:\n\n")

      @op.on('-c=COMMAND', '--cmd=COMMAND', COMMANDS, 'Command to run')
      @op.on('--db=DB', 'Use DB file instead of Calendar',
             "(default: #{$defaults[:common][:db]}",
             'For the tasks commands this should be a directory containing .sqlite files',
             "(default: #{$defaults[:tasks][:db]})")
      @op.on('--cf=FILE', "Set config file path (default: #{$defaults[:common][:cf]})")
      @op.on('--norc', 'Ignore ICALPAL and ICALPAL_CONFIG environment variables')
      @op.on('-o', '--output=FORMAT', OUTFORMATS,
             "Print as FORMAT (default: #{$defaults[:common][:output]})", "[#{OUTFORMATS.join(', ')}]")

      # include/exclude
      @op.separator("\nIncluding/excluding accounts, calendars, items:\n\n")

      @op.on('--is=ACCOUNTS', Array, 'List of accounts to include')
      @op.on('--es=ACCOUNTS', Array, 'List of accounts to exclude')

      @op.separator('')
      @op.on('--it=TYPES', Array, 'List of calendar types to include')
      @op.on('--et=TYPES', Array, 'List of calendar types to exclude',
             "[#{EventKit::EKSourceType.map { |i| i[:name] }.join(', ')}]")

      @op.separator('')
      @op.on('--ic=CALENDARS', Array, 'List of calendars to include')
      @op.on('--ec=CALENDARS', Array, 'List of calendars to exclude')

      @op.separator('')
      @op.on('--il=LISTS', Array, 'List of reminder lists to include')
      @op.on('--el=LISTS', Array, 'List of reminder lists to exclude')

      @op.separator('')
      @op.on('--id', 'Include completed reminders')
      @op.on('--ed', 'Exclude uncompleted reminders')

      @op.separator('')
      @op.on('--match=FIELD=REGEX', String, 'Include only items whose FIELD matches REGEX (ignoring case)')

      # dates
      @op.separator("\nChoosing dates:\n\n")

      @op.on('--from=DATE', RDT, 'List events starting on or after DATE')
      @op.on('--to=DATE', RDT, 'List events starting on or before DATE',
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
      @op.on('--itp=PROPERTIES', Array, 'List of task properties to include')
      @op.on('--etp=PROPERTIES', Array, 'List of task properties to exclude')
      @op.on('--atp=PROPERTIES', Array, 'List of task properties to include in addition to the default list',
             'Included for backwards compatability, these are aliases for --iep, --eep, and --aep')
      @op.separator('')

      @op.on('--uid', 'Show event UIDs')
      @op.on('--eed', 'Exclude end datetimes')

      @op.separator('')
      @op.on('--nc', 'No calendar names')
      @op.on('--npn', 'No property names')
      @op.on('--nrd', 'No relative dates')

      @op.separator('')
      @op.separator("#{@op.summary_indent}Properties are listed in the order specified")
      @op.separator('')
      @op.separator("#{@op.summary_indent}Use 'all' for PROPERTIES to include all available properties (except any listed in --eep)")
      @op.separator("#{@op.summary_indent}Use 'list' for PROPERTIES to list all available properties and exit")

      # formatting
      @op.separator("\nFormatting the output:\n\n")

      @op.on('--li=N', OptionParser::DecimalInteger, 'Show at most N items (default: 0 for no limit)')

      @op.separator('')
      @op.on('--sc', 'Separate by calendar')
      @op.on('--sd', 'Separate by date')
      @op.on('--sp', 'Separate by priority')
      @op.on('--sep=PROPERTY', 'Separate by PROPERTY')
      @op.separator('')
      @op.on('--sort=PROPERTY', 'Sort by PROPERTY')
      @op.on('--std', 'Sort tasks by due date (same as --sort=due_date)')
      @op.on('--stda', 'Sort tasks by due date (ascending) (same as --sort=due_date -r)')
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
      @op.on('--ab=STRING', String, 'Use STRING for alert bullets')
      @op.on('--nb', 'Do not use bullets')
      @op.on('--nnr=SEPARATOR', String, 'Set replacement for newlines within notes')

      @op.separator('')
      @op.on('-f', 'Format output using standard ANSI colors')
      @op.on('--color', 'Format output using a larger color palette')

      # help
      @op.separator("\nHelp:\n\n")

      @op.on('-h', '--help', 'Show this message') { @op.abort(@op.help) }
      @op.on('-V', '-v', '--version', "Show version and exit (#{@op.version})") { @op.abort(@op.version) }
      @op.on('-d', '--debug=LEVEL', /#{Regexp.union(Logger::SEV_LABEL[0..-2]).source}/i,
             "Set the logging level (default: #{Logger::SEV_LABEL[$defaults[:common][:debug]].downcase})",
             "[#{Logger::SEV_LABEL[0..-2].join(', ').downcase}]")

      # environment variables
      @op.on_tail("\nEnvironment variables:\n\n")

      @op.on_tail('%s%s %sAdditional arguments' % pad('ICALPAL'))
      @op.on_tail('%s%s %sAdditional arguments from a file' % pad('ICALPAL_CONFIG'))
      @op.on_tail("%s%s %s(default: #{$defaults[:common][:cf]})" % pad(''))

      @op.on_tail('')

      note = 'Do not quote or escape values.'
      note += '  Options set in ICALPAL override ICALPAL_CONFIG.'
      note += '  Options on the command line override ICALPAL.'

      @op.on_tail("#{@op.summary_indent}#{note}")
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

        # Load from CLI
        @op.parse!(into: cli)

        # Environment variable needs special parsing.
        # OptionParser.parse doesn't handle whitespace in a
        # comma-separated value.
        begin
          o = []

          ENV['ICALPAL'].gsub(/^-/, ' -').split(' -').each do |e|
            a = e.split(' ', 2)

            if a[0]
              o.push("-#{a[0]}")
              o.push(a[1]) if a[1]
            end
          end

          @op.parse!(o, into: env)
        end if ENV['ICALPAL'] && !cli[:norc]

        # Configuration file needs special parsing for the same reason
        begin
          o = []

          cli[:cf] ||= ENV['ICALPAL_CONFIG'] || $defaults[:common][:cf]

          File.read(File.expand_path(cli[:cf])).split("\n").each do |line|
            a = line.split(' ', 2)

            if a[0] && a[0][0] != '#'
              o.push(a[0])
              o.push(a[1]) if a[1]
            end
          end

          @op.parse!(o, into: cf)
        rescue StandardError
        end unless cli[:norc] && !cli[:cf]

        # Find command
        cli[:cmd] ||= @op.default_argv[0]
        cli[:cmd] ||= env[:cmd] if env[:cmd]
        cli[:cmd] ||= cf[:cmd] if cf[:cmd]

        # Must have a command
        raise(OptionParser::MissingArgument, 'COMMAND is required') unless cli[:cmd]

        # Handle command aliases
        cli[:cmd] = 'accounts' if cli[:cmd] == 'stores'
        cli[:cmd] = cli[:cmd].sub('reminders', 'tasks')
        cli[:cmd] = cli[:cmd].sub('datedReminders', 'datedTasks')

        # Handle events command variants
        cli[:cmd].match('events(?<v>Now|Today|Remaining)(?<n>\+[0-9]+)?') do |m|
          cli[:cmd] = 'events'

          case m.named_captures['v']
          when 'Now'
            cli[:now] = true

          when 'Today'
            cli[:from] = $today
            cli[:days] = (m.named_captures['n'])? m.named_captures['n'].to_i : 1

          when 'Remaining'
            cli[:from] = RDT.from_time($now)
            cli[:to] = $today.day_end(0)
            cli[:days] = 1
          end
        end

        # Handle tasks command variants
        if cli[:cmd] =~ /tasks/i
          cli[:dated] = cli[:cmd]

          if cli[:dated] == 'tasksDueBefore'
            cli.delete(:days) unless cli[:days]
            cli[:from] = RDT.from_epoch(0) unless cli[:from]
            cli[:to] = $today unless cli[:to]
          end

          cli[:cmd] = 'tasks'
        end

        # Must have a valid command
        raise(OptionParser::InvalidArgument, "Unknown COMMAND #{cli[:cmd]}") unless (COMMANDS.any? cli[:cmd])

        # Merge options
        opts = $defaults[:common]
          .merge($defaults[cli[:cmd].to_sym])
          .merge(cf)
          .merge(env)
          .merge(cli)

        # Make sure opts[:db] and opts[:tasks] are Arrays
        opts[:db] = [ opts[:db] ] unless opts[:db].is_a?(Array)
        opts[:tasks] = [ opts[:tasks] ] unless opts[:db].is_a?(Array)

        # All kids love log!
        $log.level = opts[:debug]

        # For posterity
        opts[:ruby] = RUBY_VERSION
        opts[:version] = @op.version

        # From the Department of Redundancy Department
        opts[:iep] = opts[:itp] if opts[:itp]
        opts[:eep] = opts[:etp] if opts[:etp]
        opts[:aep] = opts[:atp] if opts[:atp]

        opts[:props] = (opts[:iep] + opts[:aep] - opts[:eep]).uniq

        # From, to, days
        opts[:days] -= 1 if opts[:days]

        if opts[:from]
          # -n
          opts[:from] = RDT.from_time($now) if opts[:n]

          # Default :to is :from + 1 day
          # --days overrides
          opts[:to] ||= opts[:from] + 1 if opts[:from]
          opts[:to] = opts[:from] + opts[:days] if opts[:days]

          # Make :to be end of day
          opts[:to] = opts[:to].day_end

          # Calculate days unless specified
          opts[:days] ||= Integer(opts[:to] - opts[:from])
        end

        # Sorting
        opts[:sort] = 'due_date' if opts[:std] || opts[:stda]
        opts[:reverse] = true if opts[:std]

        # Colors
        opts[:palette] = 8 if opts[:f]
        opts[:palette] = 24 if opts[:color]

        # Sections
        unless opts[:sep]
          opts[:sep] = 'calendar' if opts[:sc]
          opts[:sep] = 'sday' if opts[:sd]
          opts[:sep] = 'long_priority' if opts[:sp]
        end
        opts[:nc] = true if opts[:sc]

        # Sanity checks
        raise(OptionParser::InvalidArgument, '--li cannot be negative') if opts[:li].negative?
        raise(OptionParser::InvalidOption, 'Start date must be before end date') if opts[:from] && opts[:from] > opts[:to]
        raise(OptionParser::MissingArgument, 'No properties to display') if opts[:props].empty?
        raise(OptionParser::InvalidArgument, 'Cannot use remind output with tasks') if opts[:cmd] == 'tasks' &&
          opts[:output] == 'remind'

      rescue StandardError => e
        @op.abort("#{e}\n\n#{@op.help}\n#{e}")
      end

      opts.sort.to_h
    end

    # Commands that can be run
    COMMANDS = %w[events eventsToday eventsNow eventsRemaining
                  tasks datedTasks undatedTasks tasksDueBefore
                  calendars accounts].freeze

    # Supported output formats
    OUTFORMATS = %w[ansi csv default hash html json md rdoc remind toc xml yaml].freeze

    private

    # Pad non-options to align with options
    #
    # @param t [String] Text on the left side
    #
    # @return [Array<String>] Array containing +summary_indent+, +t+,
    # a number of spaces equal to (+summary_width+ - +t.length+)
    def pad(t)
      [ @op.summary_indent, t, ' ' * (@op.summary_width - t.length) ]
    end

  end
end

# rubocop: enable Style/FormatString, Style/FormatStringToken
