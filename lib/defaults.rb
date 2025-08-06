# Does anybody really know what time it is?
now = Time.now
$now = ICalPal::RDT.from_time(now)
$today = ICalPal::RDT.new(*$now.to_a[0..2] + [ 0, 0, 0 ])

# Defaults
$defaults = {
  common: {
    ab: '!',
    aep: [],
    bullet: '•',
    cf: "#{Dir.home}/.icalpal",
    color: false,
    db: [
      "#{Dir.home}/Library/Group Containers/group.com.apple.calendar/Calendar.sqlitedb",
      "#{Dir.home}/Library/Calendars/Calendar.sqlitedb",
    ],
    debug: Logger::WARN,
    df: '%b %-d, %Y',
    ec: [],
    eep: [],
    el: [],
    es: [],
    et: [],
    ic: [],
    il: [],
    is: [],
    it: [],
    li: 0,
    norc: false,
    output: 'default',
    ps: [ "\n  " ],
    r: false,
    match: nil,
    sc: false,
    sd: false,
    sep: false,
    sort: nil,
    sp: false,
    tf: '%-I:%M %p',
  },

  tasks: {
    dated: 0,
    db: [ ICalPal::Reminder::DB_PATH ],
    iep: %w[ title notes due priority ],
    ps: [ "\n    " ],
    sort: 'prio',
  },

  undatedTasks: {
    dated: 1,
    db: [ ICalPal::Reminder::DB_PATH ],
    iep: %w[ title notes due priority ],
    ps: [ "\n    " ],
    sort: 'prio',
  },

  datedTasks: {
    dated: 2,
    db: [ ICalPal::Reminder::DB_PATH ],
    iep: %w[ title notes due priority ],
    ps: [ "\n    " ],
    sort: 'prio',
  },

  accounts: {
    iep: %w[ account type ],
    sort: 'account',
  },

  calendars: {
    iep: %w[ calendar type UUID ],
    sort: 'calendar',
  },

  events: {
    days: nil,
    ea: false,
    eed: false,
    eep: [],
    from: $today,
    iep: %w[ title location notes url attendees datetime ],
    n: false,
    nnr: "\n       ",
    nrd: false,
    now: false,
    ps: [ "\n    " ],
    sa: false,
    sed: false,
    sort: 'sctime',
    ss: "\n------------------------",
    to: nil,
    uid: false,
  }
}
