# Constants from EventKit[https://developer.apple.com/documentation/eventkit/]
class EventKit
  EKEntityType = [
    'event',
    'reminder',
  ]

  EKEventAvailability = {
    notSupported: -1,
    busy: 0,
    free: 1,
    tentative: 2,
    unavailable: 3,
  }

  EKEventStatus = {
    none: 0,
    confirmed: 1,
    tentative: 2,
    canceled: 3,
  }

  EKRecurrenceFrequency = [
    'daily',
    'weekly',
    'monthly',
    'yearly',
  ]

  EKReminderProperty = [
    'none',                     # 0
    'high', nil, nil, nil,      # 1
    'medium', nil, nil, nil,    # 5
    'low',                      # 9
  ]

  # EKSourceType (with color)
  EKSourceType = [
    { name: 'Local',      color: '#FFFFFF' }, # White
    { name: 'Exchange',   color: '#00FFFF' }, # Cyan
    { name: 'CalDAV',     color: '#00FF00' }, # Green
    { name: 'MobileMe',   color: '#FFFF00' }, # Yellow
    { name: 'Subscribed', color: '#FF0000' }, # Red
    { name: 'Birthdays',  color: '#FF00FF' }, # Magenta
    { name: 'Reminders',  color: '#066FF3' }, # Blue
  ]

  EKSpan = [
    'this',
    'future',
  ]
end
