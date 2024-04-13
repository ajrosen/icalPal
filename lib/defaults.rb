# Does anybody really know what time it is?
$now = ICalPal::RDT.now
$today = ICalPal::RDT.new(*$now.to_a[0..2] + [0, 0, 0, $now.zone])

# Defaults
$defaults = {
  common: {
    aep: [],
    bullet: '•',
    cf: "#{ENV['HOME']}/.icalPal",
    color: false,
    db: "#{ENV['HOME']}/Library/Calendars/Calendar.sqlitedb",
    debug: Logger::WARN,
    df: '%b %-d, %Y',
    ec: [],
    eep: [],
    es: [],
    et: [],
    ic: [],
    is: [],
    it: [],
    li: 0,
    output: 'default',
    ps: [ "\n  " ],
    r: false,
    sc: false,
    sd: false,
    sep: false,
    sort: nil,
    sp: false,
    tf: '%-I:%M %p',
  },
  tasks: {
    db: ICalPal::Reminder::DB_PATH,
    iep: [ 'title', 'notes', 'due', 'priority' ],
    sort: 'prio',
    undated: false,
  },
  undatedTasks: {
    db: ICalPal::Reminder::DB_PATH,
    iep: [ 'title', 'notes', 'due', 'priority' ],
    sort: 'prio',
    undated: true,
  },
  stores: {
    iep: [ 'account', 'type' ],
    sort: 'account',
  },
  calendars: {
    iep: [ 'calendar', 'type', 'UUID' ],
    sort: 'calendar',
  },
  events: {
    days: nil,
    ea: false,
    eed: false,
    eep: [],
    from: $today,
    iep: [ 'title', 'location', 'notes', 'url', 'attendees', 'datetime' ],
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
