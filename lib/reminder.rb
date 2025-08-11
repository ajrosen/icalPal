r 'timezone'

# Images
# Section

module ICalPal
  # Class representing items from the <tt>Reminders</tt> database
  class Reminder
    include ICalPal

    def self.load_data(db_file, q)
      # Load items
      ICalPal.load_data(db_file, q)
    end

    def [](k)
      case k
      when 'alert'              # -N (minutes|hours|days|weeks|months)
        if @self['alert']
          alert = JSON.parse(@self['alert'])['dueDateDeltaAlerts'][0]
          count = alert['dueDateDeltaCount'] * -1
          unit = EventKit::EKReminderDueDateDeltaUnit[alert['dueDateDeltaUnit']]
          "#{count} #{unit}"
        end

      when 'assignee'           # [ nickname, firstname, lastname, address ]
        if @self['assignee']
          a = @self['assignee']
          t = (a[0])? a[0] : "#{a[1]} #{a[2]}"
          t += " (#{a[3][7..]})" if a[3]
          t
        end

      when 'due'                # date[ at time]
        if @self['due']
          t = @self['due'].to_s
          t += " at #{@self['due'].strftime($opts[:tf])}" unless @self['all_day'] == 1
          t
        end

      when 'group'              # (group|"(no group)")
        (@self['group'])? @self['group'] : '(no group)'

      when 'priority'           # Integer -> String
        EventKit::EKReminderPriority[@self['priority']] if @self['priority'].positive?

      when 'proximity'          # (arriving|leaving)
        EventKit::EKReminderProximity[@self['proximity']] if @self['proximity']

      when 'radius'             # Float -> Integer
        "#{Integer(@self['radius'])}m" if @self['radius']

      when 'sdate'              # For sorting
        @self['due_date']

      when 'name', 'reminder', 'task' # Aliases
        @self['title']

      else @self[k]
      end
    end

    def initialize(obj)
      super

      # Convert JSON arrays to Arrays
      @self['tags'] = JSON.parse(obj['tags']) if obj['tags']
      @self['location'] = JSON.parse(obj['location']).compact.uniq[0] if obj['location']
      @self['proximity'] = JSON.parse(obj['proximity']).compact.uniq[0] if obj['proximity']
      @self['radius'] = JSON.parse(obj['radius']).compact.uniq[0] if obj['radius']
      @self['assignee'] = JSON.parse(obj['assignee']) if obj['assignee']

      # Section
      if @self['members']
        j = JSON.parse(@self['members']).select { |i| i['memberID'] == @self['id'] }
        s = $sections.select { |i| i['id'] == j[0]['groupID'] } if j[0]
        @self['section'] = s[0]['name'] if s && s[0]

        @self.delete('members')
        @self.delete('id')
      end

      # Priority
      # rubocop: disable Style/NumericPredicate
      @self['prio'] = 0 if @self['priority'] == 1 # high
      @self['prio'] = 1 if @self['priority'] == 5 # medium
      @self['prio'] = 2 if @self['priority'] == 9 # low
      @self['prio'] = 3 if @self['priority'] == 0 # none
      # rubocop: enable Style/NumericPredicate

      @self['long_priority'] = LONG_PRIORITY[@self['prio']] if @self['prio']

      # For sorting
      @self['sdate'] = (@self['title'])? @self['title'] : ''

      # Due date
      if @self['due_date']
        begin
          @self['due_date'] += ITIME
          zone = Timezone.fetch(@self['timezone'])
        rescue Timezone::Error::InvalidZone
          zone = '+00:00'
        end

        @self['due'] = RDT.from_time(Time.at(@self['due_date'], in: zone))
      end

      # Notes
      @self['notes'] = '' unless @self['notes']

      # Color
      @self['color'] = nil unless $opts[:palette]

      if @self['color']
        plist = plconvert(@self['color'])

        # Get color and symbolic color name
        plist.each do |p|
          @self['color'] = plist[p['daHexString']['CF$UID']] if p['daHexString']
          @self['symbolic_color_name'] = plist[p['ckSymbolicColorName']['CF$UID']] if p['ckSymbolicColorName']
        end
      else
        @self['color'] = DEFAULT_COLOR
        @self['symbolic_color_name'] = DEFAULT_SYMBOLIC_COLOR
      end

      # Contacts
      messaging = []

      plist = plconvert(@self['messaging'])
      plist.each do |p|
        %w[ emails phones ].each do |field|
          next unless p[field]

          offset = p[field].values[0]
          targets = plist[offset]['NS.objects']
          targets.each { |t| messaging.push(plist[t['CF$UID']]) }
        end
      end if plist

      @self['messaging'] = messaging
    end

    DEFAULT_COLOR = '#1BADF8'.freeze
    DEFAULT_SYMBOLIC_COLOR = 'blue'.freeze

    LONG_PRIORITY = [
      'High priority',
      'Medium priority',
      'Low priority',
      'No priority',
    ].freeze

    DB_PATH = "#{Dir.home}/Library/Group Containers/group.com.apple.reminders/Container_v1/Stores".freeze

    QUERY = <<~SQL.freeze
SELECT DISTINCT

r1.zTitle as title,
r1.zAllday as all_day,
r1.zDueDate as due_date,
r1.zFlagged as flagged,
r1.zNotes as notes,
r1.zPriority as priority,
r1.zContactHandles as messaging,
r1.zDueDateDeltaAlertsData as alert,
r1.zTimezone as timezone,
r1.zckIdentifier as id,

bl1.zBadgeEmblem as badge,
bl1.zColor as color,
bl1.zName as list_name,
bl1.zParentList as parent,
bl1.zSharingStatus as shared,

-- section members
json(bl1.ZMembershipsOfRemindersInSectionsAsData) -> '$.memberships' AS members,

-- group
(SELECT zName
 FROM zremcdBaseList bl2
 WHERE bl2.z_pk = bl1.zParentList) AS 'group',

-- location
(SELECT json_group_array(zremcdObject.zTitle)
FROM zremcdObject
WHERE zremcdObject.z_pk IN (
 SELECT zTrigger
 FROM zremcdObject
 WHERE zremcdObject.zReminder = r1.z_pk
)) AS location,

-- proximity
(SELECT json_group_array(zremcdObject.zProximity)
 FROM zremcdObject
 WHERE zremcdObject.z_pk IN (
  SELECT zTrigger
  FROM zremcdObject
  WHERE zremcdObject.zReminder = r1.z_pk
 )) AS proximity,

-- radius
(SELECT json_group_array(zremcdObject.zRadius)
 FROM zremcdObject
 WHERE zremcdObject.z_pk IN (
  SELECT zTrigger
  FROM zremcdObject
  WHERE zremcdObject.zReminder = r1.z_pk
 )) AS radius,

-- tags
(SELECT json_group_array(zName)
 FROM zremcdHashtagLabel
 WHERE zremcdHashtagLabel.z_pk IN (
	SELECT zremcdObject.zHashtagLabel
	FROM zremcdObject
	JOIN zremcdreminder ON zremcdObject.zReminder3 = r1.z_pk
	WHERE zremcdObject.zReminder3 = r1.z_pk
 )) AS tags,

-- assignee
(SELECT
 json_array(zNickname, zFirstName, zLastName, zAddress1)
 FROM zremcdObject
 WHERE z_pk = (
  SELECT zAssignee
  FROM zremcdObject
  WHERE zReminder1 = r1.z_pk
)) AS assignee,

-- url
(SELECT zURL
 FROM zremcdObject
 WHERE zReminder2 = r1.z_pk) AS url

FROM zremcdReminder r1

LEFT OUTER JOIN zremcdBaseList bl1 ON r1.zList = bl1.z_pk

WHERE r1.zCompleted = 0
AND r1.zMarkedForDeletion = 0

SQL

    # Load sections
    SECTIONS_QUERY = <<~SQL.freeze
SELECT DISTINCT

zckIdentifier AS id,
zDisplayName AS name

FROM zremcdBaseSection

SQL

  end
end
