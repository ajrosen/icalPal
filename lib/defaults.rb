# Does anybody really know what time it is?
$now = ICalPal::RDT.now
$today = ICalPal::RDT.new(*$now.to_a[0..2] + [ 0, 0, 0, $now.zone ])

# Defaults
$defaults = {
  common: {
    ab: '!',
    aep: [],
    bullet: '•',
    cf: "#{ENV['HOME']}/.icalpal",
    color: false,
    db: [
      "#{ENV['HOME']}/Library/Group Containers/group.com.apple.calendar/Calendar.sqlitedb",
      "#{ENV['HOME']}/Library/Calendars/Calendar.sqlitedb",
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
    sort: 'prio',
  },
  undatedTasks: {
    dated: 1,
    db: [ ICalPal::Reminder::DB_PATH ],
    iep: %w[ title notes due priority ],
    sort: 'prio',
  },
  datedTasks: {
    dated: 2,
    db: [ ICalPal::Reminder::DB_PATH ],
    iep: %w[ title notes due priority ],
    sort: 'prio',
  },
  stores: {
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
    ps: [ "\n    " ],
    sa: false,
    sed: false,
    sort: 'sdate',
    ss: "\n------------------------",
    to: nil,
    uid: false,
  }
}
