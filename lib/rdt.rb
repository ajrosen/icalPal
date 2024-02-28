require 'date'

module ICalPal
  # Child class of DateTime that adds support for relative dates (<em><b>R</b>elative<b>D</b>ate<b>T</b>ime</em>).
  class RDT < DateTime
    # Convert a String to an RDT
    #
    # @param str [String] can be +yesterday+, +today+, +tomorrow+,
    #  <code>+N</code>, or +-N+.  Otherwise use DateTime.parse.
    #
    # @return [RDT] a new RDT
    def self.conv(str)
      case str
      when 'yesterday' then $today - 1
      when 'today' then $today
      when 'tomorrow' then $today + 1
      when /^\+([0-9]+)/ then $today + $1.to_i
      when /^\-([0-9]+)/ then $today - $1.to_i
      else parse(str)
      end
    end

    # Values can be +day before yesterday+, +yesterday+,
    # +today+, +tomorrow+, +day after tomorrow+, or the result from
    # strftime
    #
    # @return [String] A string representation of self relative to
    #  today.
    def to_s
      return strftime($opts[:df]) if $opts[:nrd] && $opts[:df]

      case Integer(RDT.new(year, month, day) - $today)
      when -2 then 'day before yesterday'
      when -1 then 'yesterday'
      when 0 then 'today'
      when 1 then 'tomorrow'
      when 2 then 'day after tomorrow'
      else strftime($opts[:df]) if $opts[:df]
      end
    end

    alias inspect to_s
 
    # @see Time.to_a
    #
    # @return [Array] Self as an array
    def to_a
      [ year, month, day, hour, min, sec ]
    end

    # @return [Integer] Seconds since epoch
    def to_i
      to_time.to_i
    end
  end
end
