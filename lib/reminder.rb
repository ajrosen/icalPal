r 'open3'
r 'plist'

module ICalPal
  # Class representing items from the <tt>Reminders</tt> database
  class Reminder
    include ICalPal

    def [](k)
      case k
      when 'notes'              # Skip empty notes
        (@self['notes'].empty?)? nil : @self['notes']

      when 'priority'           # Integer -> String
        EventKit::EKReminderPriority[@self['priority']] if @self['priority'].positive?

      when 'sdate'              # For sorting
        @self['title']

      else @self[k]
      end
    end

    def initialize(obj)
      @self = {}
      obj.each_key { |k| @self[k] = obj[k] }

      # Priority
      # rubocop: disable Style/NumericPredicate
      @self['prio'] = 0 if @self['priority'] == 1 # high
      @self['prio'] = 1 if @self['priority'] == 5 # medium
      @self['prio'] = 2 if @self['priority'] == 9 # low
      @self['prio'] = 3 if @self['priority'] == 0 # none
      # rubocop: enable Style/NumericPredicate

      @self['long_priority'] = LONG_PRIORITY[@self['prio']]

      # For sorting
      @self['sdate'] = (@self['title'])? @self['title'] : ''

      # Due date
      @self['due'] = RDT.new(*Time.at(@self['due_date'] + ITIME).to_a.reverse[4..]) if @self['due_date']
      @self['due_date'] = 0 unless @self['due_date']

      # Notes
      @self['notes'] = '' unless @self['notes']

      # Color
      @self['color'] = nil unless $opts[:palette]

      if @self['color']
        # Run command
        stdin, stdout, _stderr, _e = Open3.popen3(PL_CONVERT)

        # Send color bplist
        stdin.write(@self['color'])
        stdin.close

        # Read output
        plist = Plist.parse_xml(stdout.read)['$objects']

        @self['color'] = plist[3]
        @self['symbolic_color_name'] = (plist[2] == 'custom')? plist[4] : plist[2]
      else
        @self['color'] = DEFAULT_COLOR
        @self['symbolic_color_name'] = DEFAULT_SYMBOLIC_COLOR
      end
    end

    DEFAULT_COLOR = '#1BADF8'.freeze
    DEFAULT_SYMBOLIC_COLOR = 'blue'.freeze

    LONG_PRIORITY = [
      'High priority',
      'Medium priority',
      'Low priority',
      'No priority',
    ].freeze

    PL_CONVERT = '/usr/bin/plutil -convert xml1 -o - -'.freeze

    DB_PATH = "#{Dir.home}/Library/Group Containers/group.com.apple.reminders/Container_v1/Stores".freeze

    QUERY = <<~SQL.freeze
SELECT DISTINCT

zremcdReminder.zAllday as all_day,
zremcdReminder.zDuedate as due_date,
zremcdReminder.zFlagged as flagged,
zremcdReminder.zNotes as notes,
zremcdReminder.zPriority as priority,
zremcdReminder.zTitle as title,

zremcdBaseList.zBadgeEmblem as badge,
zremcdBaseList.zColor as color,
zremcdBaseList.zName as list_name,
zremcdBaseList.zParentList as parent,
zremcdBaseList.zSharingStatus as shared

FROM zremcdReminder

JOIN zremcdBaseList ON zremcdReminder.zList = zremcdBaseList.z_pk

WHERE zremcdReminder.zCompleted = 0
AND zremcdReminder.zMarkedForDeletion = 0

SQL

  end
end
