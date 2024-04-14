require 'open3'
require 'nokogiri-plist'

module ICalPal
  # Class representing items from the <tt>Reminders</tt> database
  class Reminder
    include ICalPal

    def [](k)
      case k
      when 'notes' then         # Skip empty notes
        @self['notes'].length > 0? @self['notes'] : nil

      when 'priority' then      # Integer -> String
        EventKit::EKReminderProperty[@self['priority']] if @self['priority'] > 0

      when 'sdate' then         # For sorting
        @self['title']

      else @self[k]
      end
    end

    def initialize(obj)
      @self = {}
      obj.keys.each { |k| @self[k] = obj[k] }

      # Priority
      @self['prio'] = 0 if @self['priority'] == 1 # high
      @self['prio'] = 1 if @self['priority'] == 5 # medium
      @self['prio'] = 2 if @self['priority'] == 9 # low
      @self['prio'] = 3 if @self['priority'] == 0 # none

      @self['long_priority'] = LONG_PRIORITY[@self['prio']]

      # For sorting
      @self['sdate'] = (@self['title'])? @self['title'] : ""

      # Due date
      @self['due'] = RDT.new(*Time.at(@self['due_date'] + ITIME).to_a.reverse[4..]) if @self['due_date']
      @self['due_date'] = 0 unless @self['due_date']

      # Notes
      @self['notes'] = "" unless @self['notes']

      # Color
      @self['color'] = nil unless $opts[:palette]

      if @self['color'] then
        # Run command
        stdin, stdout, stderr, e = Open3.popen3(PL_CONVERT)

        # Send color bplist
        stdin.write(@self['color'])
        stdin.close

        # Read output
        plist = Nokogiri::PList(stdout.read)['$objects']

        @self['color'] = plist[3]
        @self['symbolic_color_name'] = (plist[2] == 'custom')? plist[4] : plist[2]
      else
        @self['color'] = DEFAULT_COLOR
        @self['symbolic_color_name'] = DEFAULT_SYMBOLIC_COLOR
      end
    end

    private

    DEFAULT_COLOR = '#1BADF8'
    DEFAULT_SYMBOLIC_COLOR = 'blue'

    LONG_PRIORITY = [
      "High priority",
      "Medium priority",
      "Low priority",
      "No priority",
    ]

    PL_CONVERT = '/usr/bin/plutil -convert xml1 -o - -'

    DB_PATH = "#{Dir::home}/Library/Group Containers/group.com.apple.reminders/Container_v1/Stores"

    QUERY = <<~SQL
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
