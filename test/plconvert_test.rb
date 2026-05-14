# Tests for plconvert in lib/utils.rb.
#
# Run via:
#   ruby test/plconvert_test.rb

require 'minitest/autorun'
require 'open3'
require 'stringio'

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

class PlconvertTest < Minitest::Test
  # Replace Open3.popen3 with a recording stub for the duration of the
  # block. Each call appends its argument list to +log+ and returns a
  # tuple shaped like the real popen3 result. Avoids depending on
  # Minitest::Mock (removed in minitest 6.x).
  def with_popen3_stub
    log = []
    Open3.singleton_class.send(:alias_method, :_orig_popen3, :popen3)
    Open3.define_singleton_method(:popen3) do |*args|
      log << args
      [
        StringIO.new(+'', 'w'),
        StringIO.new('<?xml version="1.0"?><plist></plist>'),
        StringIO.new,
        Object.new
      ]
    end
    yield log
  ensure
    Open3.singleton_class.send(:alias_method, :popen3, :_orig_popen3)
    Open3.singleton_class.send(:remove_method, :_orig_popen3)
  end

  def setup
    PLCONVERT_CACHE.clear
  end

  def test_returns_nil_for_nil_input_without_spawning_a_subprocess
    with_popen3_stub do |log|
      assert_nil plconvert(nil)
      assert_empty log,
                   'plconvert(nil) must not fork plutil'
    end
  end

  def test_returns_nil_for_empty_string_without_spawning_a_subprocess
    with_popen3_stub do |log|
      assert_nil plconvert('')
      assert_empty log,
                   'plconvert("") must not fork plutil'
    end
  end

  def test_memoizes_by_input_bytes
    with_popen3_stub do |log|
      plconvert('the-same-blob')
      plconvert('the-same-blob')
      plconvert('the-same-blob')
      assert_equal 1, log.size,
                   'plconvert should only fork plutil once per unique input'
    end
  end

  def test_distinct_blobs_each_spawn_their_own_subprocess
    with_popen3_stub do |log|
      plconvert('blob-A')
      plconvert('blob-B')
      assert_equal 2, log.size
    end
  end

  def test_caches_nil_results_so_a_failing_blob_is_not_retried
    Open3.singleton_class.send(:alias_method, :_orig_popen3, :popen3)
    log = []
    Open3.define_singleton_method(:popen3) do |*args|
      log << args
      [
        StringIO.new(+'', 'w'),
        StringIO.new('not-a-plist'),
        StringIO.new,
        Object.new
      ]
    end

    begin
      assert_nil plconvert('bad-blob')
      assert_nil plconvert('bad-blob')
      assert_equal 1, log.size,
                   'a blob that produced nil should still be cached'
    ensure
      Open3.singleton_class.send(:alias_method, :popen3, :_orig_popen3)
      Open3.singleton_class.send(:remove_method, :_orig_popen3)
    end
  end
end
