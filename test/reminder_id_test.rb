# Regression test for the section-handling code in ICalPal::Reminder#initialize.
# Prior to the fix, `id` (the CloudKit identifier from zckIdentifier) was
# deleted from the reminder hash whenever the reminder belonged to a
# sectioned list. Every Apple grocery list uses sections, plus any user
# list with sections configured, so in practice ~85% of reminders had
# their id stripped — breaking downstream consumers that need the
# identifier for joins or deduplication.
#
# Run via:
#   ruby test/reminder_id_test.rb

require 'minitest/autorun'

# icalPal's lib/icalPal.rb uses `rr` and `r` helpers defined in bin/icalPal,
# so requiring the lib directly fails. Define them here, then load.
def r(gem)
  require gem
end

def rr(library)
  require_relative File.join(__dir__, '..', 'lib', library.to_s)
end

%w[ logger csv json rdoc sqlite3 yaml ].each { |g| r(g) }
%w[ icalPal defaults options utils ].each { |l| rr(l) }

class ReminderIdPreservationTest < Minitest::Test

  def setup
    # ICalPal::Reminder#initialize touches a few globals: $opts (for
    # color/palette logic), $sections (for the section lookup we're
    # testing). Set minimal defaults that exercise the section block
    # without needing a real DB.
    $opts = { palette: false, tf: '%H:%M' }
    $sections = []
  end

  def test_id_is_preserved_when_reminder_belongs_to_a_sectioned_list
    obj = synthetic_row(
      'id'      => 'CKID-PRESERVE-ME',
      'members' => '[{"memberID":"CKID-PRESERVE-ME","groupID":"section-A"}]'
    )

    reminder = ICalPal::Reminder.new(obj)

    refute_nil reminder['id'],
               'expected id to be preserved on a sectioned-list reminder; ' \
               'instead it was deleted (regression of the section-handling block)'
    assert_equal 'CKID-PRESERVE-ME', reminder['id']
  end

  def test_id_is_preserved_when_reminder_is_not_in_a_sectioned_list
    obj = synthetic_row(
      'id'      => 'CKID-NORMAL',
      'members' => nil
    )

    reminder = ICalPal::Reminder.new(obj)

    assert_equal 'CKID-NORMAL', reminder['id']
  end

  def test_members_is_still_dropped_from_output
    obj = synthetic_row(
      'id'      => 'CKID-CHECK-MEMBERS',
      'members' => '[{"memberID":"CKID-CHECK-MEMBERS","groupID":"section-B"}]'
    )

    reminder = ICalPal::Reminder.new(obj)

    assert_nil reminder['members'],
               'members is internal scratch and should still be dropped from output'
  end

  def test_section_assignment_still_works
    $sections = [ { 'id' => 'section-C', 'name' => 'Produce' } ]
    obj = synthetic_row(
      'id'      => 'CKID-SECTION-TEST',
      'members' => '[{"memberID":"CKID-SECTION-TEST","groupID":"section-C"}]'
    )

    reminder = ICalPal::Reminder.new(obj)

    assert_equal 'Produce', reminder['section'],
                 'section lookup uses id internally; restoring id should not interfere'
    assert_equal 'CKID-SECTION-TEST', reminder['id']
  end

  private

  # Build a row hash with the keys ICalPal::Reminder#initialize and
  # its parent ICalPal#initialize touch unconditionally, defaulting
  # to nils where the code path is nil-guarded.
  def synthetic_row(overrides = {})
    {
      'account'   => 'Test',
      'type'      => nil, # short-circuits ICalPal#initialize EKSourceType lookup
      'priority'  => 0,
      'due_date'  => nil,
      'notes'     => nil,
      'color'     => nil,
      'messaging' => nil,
      'assignee'  => nil,
      'tags'      => nil,
      'location'  => nil,
      'proximity' => nil,
      'radius'    => nil,
      'subcal_url' => nil
    }.merge(overrides)
  end

end
