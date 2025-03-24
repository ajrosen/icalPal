require_relative 'lib/version'

Gem::Specification.new do |s|
  s.name	= ICalPal::NAME
  s.version	= ICalPal::VERSION

  s.summary	= 'Command-line tool to query the macOS Calendar'
  s.description	= <<-EOF
Inspired by icalBuddy and maintains close compatability.  Includes
many additional features for querying, filtering, and formatting.
EOF

  s.authors	= 'Andy Rosen'
  s.email	= 'ajr@corp.mlfs.org'
  s.homepage	= "https://github.com/ajrosen/#{s.name}"
  s.licenses	= [ 'GPL-3.0-or-later' ]

  s.metadata = {
    'bug_tracker_uri' => "https://github.com/ajrosen/#{s.name}/issues"
  }

  s.files	= Dir["#{s.name}.gemspec", 'bin/*', 'lib/*.rb']
  s.executables	= [ "#{s.name}" ]
  s.extra_rdoc_files = [ 'README.md' ]

  s.add_dependency 'nokogiri-plist', '~> 0.5.0'
  s.add_dependency 'sqlite3', '~> 2.6.0' unless s.rubygems_version == `/usr/bin/gem --version`.strip

  # The macOS and Homebrew versions of rubygems have incompatible
  # requirements for sqlite3.
  # 
  # macOS comes with version 1.3.13, so it does not need to be added
  # as a dependency, but it cannot install anything newer:
  # 
  # requires Ruby version >= 3.0, < 3.4.dev. The current ruby version is 2.6.10.
  # 
  # Homebrew's Ruby formula does not come with sqlite3, so it does
  # need to be added as a dependency, but it cannot install version
  # 1.3.13:
  # 
  # error: call to undeclared function
  # 
  # So we must call add_dependency, but iff we are not building with
  # macOS' Ruby installation.

  s.bindir = 'bin'
  s.required_ruby_version = '>= 2.6.0'

  s.post_install_message = <<-EOF

Note: #{ICalPal::NAME} requires "Full Disk Access" in System Settings to access your calendar.
Make sure the program that runs #{ICalPal::NAME}, not #{ICalPal::NAME} itself, has these permissions.

EOF
end
