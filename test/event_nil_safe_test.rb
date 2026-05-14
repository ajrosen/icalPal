# Regression test for Event#non_recurring when icalpal encounters
# events whose sdate / edate / duration is nil. Real Calendar.app data
# contains rows where these fields are missing (e.g. malformed
# subscribed calendars, partial syncs from CalDAV servers, or events
# that lost their date during a Sequoia migration).
#
# Prior to the fix, icalpal aborted the entire output with one of:
#
#   NoMethodError: undefined method '/' for nil:NilClass
#       (lib/event.rb:120 — `(self['duration'] / 86_400).to_i`)
#
#   ArgumentError: comparison of NilClass with ICalPal::RDT failed
#       (lib/event.rb:321 — `[ s, e ].max >= $opts[:from]` with nil e)
#
#   NoMethodError: undefined method 'to_a' for nil:NilClass
#       (lib/event.rb:126 — `@self['sdate'].to_a` with nil sdate)
#
# Run via:
#   ruby test/event_nil_safe_test.rb

require 'minitest/autorun'

# icalPal's lib uses `rr` and `r` helpers defined in bin/icalPal,
# so requiring the lib directly fails. Define them here, then load.
def r(gem)
  require gem
end

def rr(library)
  require_relative File.join(__dir__, '..', 'lib', library.to_s)
end

%w[ logger csv json rdoc sqlite3 yaml ].each { |g| r(g) }
%w[ icalPal defaults options utils ].each { |l| rr(l) }

class EventNilSafeTest < Minitest::Test
  # Build an Event-like object whose @self is the passed hash, bypassing
  # the heavy ICalPal::Event#initialize (JSON.parse on attendees, date
  # conversions, etc.) so the test focuses purely on non_recurring's
  # nil handling.
  class TestEvent < ICalPal::Event
    def initialize(self_hash)
      @self = self_hash
    end
  end

  def setup
    # ICalPal::Event#non_recurring reads $opts[:to] / $opts[:from] /
    # $opts[:now] inside the loop and the in_window? helper. Set bounds
    # that include any sdate we might construct, but ensure the loop
    # terminates after a single iteration (duration=0 → nDays=0).
    far_past   = ICalPal::RDT.new(2000, 1, 1, 0, 0, 0, '+00:00')
    far_future = ICalPal::RDT.new(2100, 1, 1, 0, 0, 0, '+00:00')
    $opts = { from: far_past, to: far_future, now: false, sep: 'date' }
    $log = Logger.new(IO::NULL)
  end

  def test_nil_sdate_returns_empty_array_instead_of_crashing
    event = TestEvent.new('sdate' => nil, 'edate' => nil, 'duration' => nil, 'title' => 'Bad row')

    # Regression: without the fix, this raised NoMethodError on '/' for nil.
    assert_equal [], event.non_recurring,
                 'nil sdate should cause non_recurring to skip the row, not crash'
  end

  def test_nil_duration_is_coerced_to_zero
    sdate = ICalPal::RDT.new(2026, 4, 24, 9, 0, 0, '+00:00')
    edate = ICalPal::RDT.new(2026, 4, 24, 10, 0, 0, '+00:00')
    event = TestEvent.new('sdate' => sdate, 'edate' => edate, 'duration' => nil, 'title' => 'No duration')

    refute_nil event.non_recurring,
               'nil duration should be coerced to 0 so non_recurring runs'
    assert_equal 0, event['duration'],
                 'duration should have been set to 0'
  end

  def test_nil_edate_is_coerced_to_sdate
    sdate = ICalPal::RDT.new(2026, 4, 24, 9, 0, 0, '+00:00')
    event = TestEvent.new('sdate' => sdate, 'edate' => nil, 'duration' => 0, 'title' => 'No edate')

    # Regression: without the fix, in_window?'s `[s, e].max` raised
    # ArgumentError on the nil edate.
    refute_nil event.non_recurring
    refute_nil event['edate'],
               'edate should have been coerced to sdate'
  end

  def test_normal_event_path_is_unaffected
    sdate = ICalPal::RDT.new(2026, 4, 24, 9, 0, 0, '+00:00')
    edate = ICalPal::RDT.new(2026, 4, 24, 10, 0, 0, '+00:00')
    event = TestEvent.new(
      'sdate'    => sdate,
      'edate'    => edate,
      'duration' => 3600,
      'title'    => 'Normal event'
    )

    result = event.non_recurring
    refute_empty result,
                 'a well-formed in-window event should still be returned'
  end
end
