PL_CONVERT = '/usr/bin/plutil -convert xml1 -o - -'.freeze

# Load a plist
#
# @param obj [String] Data that can be converted by +/usr/bin/plutil+
# @return [Array] Objects representing nodes in the plist
def plconvert(obj)
  r 'open3'
  r 'plist'

  # Run PL_CONVERT command
  sin, sout, _serr, _e = Open3.popen3(PL_CONVERT)

  # Send obj
  sin.write(obj)
  sin.close

  # Read output
  begin
    plist = Plist.parse_xml(sout.read)
    plist['$objects'] if plist
  rescue Plist::UnimplementedElementError
    nil
  end
end

# Convert a key/value pair to XML.  The value should be +nil+, +String+,
# +Integer+, +Array+, or +ICalPal::RDT+
#
# @param key The key
# @param value The value
# @return [String] The key/value pair in a simple XML format
def xmlify(key, value)
  case value
    # Nil
  when NilClass then "<#{key}/>"

    # Array
  when Array
    # Treat empty arrays as nil values
    xmlify(key, nil) if value[0].nil?

    retval = ''
    value.each { |x| retval += xmlify("#{key}0", x) }
    "<#{key}>#{retval}</#{key}>"

    # Unknown
  else "<#{key}>#{value}</#{key}>"
  end
end

# Get the application icalPal is most likely running in
#
# @return [Integer] The basename of the program whose parent process id is 1 (launchd)
def ancestor
  ppid = Process.ppid

  while (ppid != 1)
    ps = `ps -p #{ppid} -o ppid,command | tail -1`
    ppid = ps[/^[0-9 ]+ /].to_i
  end

  ps[(ps.rindex('/') + 1)..].chop
end
