begin
  require 'mkmf'
  require 'rubygems/dependency_installer'

  # Search Gem paths for one that is writable.
  gemdir = nil
  Gem.path.each { |p| gemdir = p if File.writable? p }

  # Dependencies common to all environments
  dependencies = %w[ plist ]

  # All dependencies are included with the installation of Ruby in
  # macOS. Adding these dependencies anyway will cause errors that
  # prevent icalPal from being installed.
  unless RUBY_VERSION >= '2.6'
    dependencies.push('logger')
    dependencies.push('csv')
    dependencies.push('json')
    dependencies.push('rdoc')
    dependencies.push('sqlite3')
    dependencies.push('yaml')
  end

  di = Gem::DependencyInstaller.new(install_dir: gemdir)
  dependencies.each { |d| di.install(d) }
rescue Exception
  exit(1)
end

File.write('Makefile', "clean:\n\ttrue\ninstall:\n\ttrue")

exit(0)
