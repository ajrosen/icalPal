Gem::Specification.new do |s|
  s.name	= "icalPal"
  s.version	= "1.2.1"
  s.summary	= "Command-line tool to query the macOS Calendar"
  s.description	= <<-EOF
Inspired by icalBuddy and maintains close compatability.  Includes
many additional features for querying, filtering, and formatting.
EOF

  s.authors	= "Andy Rosen"
  s.email	= "ajr@corp.mlfs.org"
  s.homepage	= "https://github.com/ajrosen/#{s.name}"
  s.licenses	= [ "GPL-3.0-or-later" ]

  s.files	= Dir[ "#{s.name}.gemspec", "bin/*", "lib/*.rb" ]
  s.executables	= [ "#{s.name}" ]
  s.extra_rdoc_files = [ "README.md" ]

  s.add_runtime_dependency "sqlite3", "~> 1"

  s.bindir = 'bin'
  s.required_ruby_version = '>= 2.6.0'
end
