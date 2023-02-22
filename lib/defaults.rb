# Does anybody really know what time it is?
$now = ICalPal::RDT.now
$today = ICalPal::RDT.new(*$now.to_a[0..2])

# Defaults
$defaults = {
  common: {
    aep: [],
    bullet: '•',
    cf: "#{ENV['HOME']}/.icalPal",
    color: false,
    db: "#{ENV['HOME']}/Library/Calendars/Calendar.sqlitedb",
    debug: Logger::WARN,
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
  },
  tasks: {
    bullet: '!',
    iep: [ 'notes', 'due', 'priority' ],
    sort: 'priority',
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
    df: '%b %-d, %Y',
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
    tf: '%-I:%M %p',
    to: nil,
    uid: false,
  }
}
