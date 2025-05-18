require_relative 'lib/version'

Gem::Specification.new do |s|
  s.name	= ICalPal::NAME
  s.version	= ICalPal::VERSION

  s.summary	= 'Command-line tool to query the macOS Calendar and Reminders'
  s.description	= <<-EOF
Inspired by icalBuddy and maintains close compatability.  Includes
many additional features for querying, filtering, and formatting.
EOF

  s.authors	= 'Andy Rosen'
  s.email	= 'ajr@corp.mlfs.org'
  s.homepage	= "https://github.com/ajrosen/#{s.name}"
  s.licenses	= [ 'GPL-3.0-or-later' ]

  s.metadata = {
    'bug_tracker_uri' => "https://github.com/ajrosen/#{s.name}/issues",
    'rubygems_mfa_required' => 'true'
  }

  s.files	= Dir["#{s.name}.gemspec", 'bin/*', 'ext/*.rb', 'lib/*.rb']
  s.executables	= [ "#{s.name}" ]
  s.extra_rdoc_files = [ 'README.md' ]

  # Some installation settings cannot be handled at build time.
  # Handle everything at installation time.
  s.extensions << 'ext/extconf.rb'

  s.bindir = 'bin'
  s.required_ruby_version = '>= 2.6.0'

  s.post_install_message = <<-EOF

Note: #{ICalPal::NAME} requires "Full Disk Access" in System Settings to access your calendar.
Make sure the program that runs #{ICalPal::NAME}, not #{ICalPal::NAME} itself, has these permissions.

EOF
end
