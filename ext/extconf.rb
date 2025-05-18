begin
  require 'mkmf'
  require 'rubygems/dependency_installer'

  # Search Gem paths for one that is writable.
  gemdir = nil
  Gem.path.each { |p| gemdir = p if File.writable? p }

  # Dependencies common to all environments
  dependencies = %w[ plist timezone ]

  if RUBY_VERSION >= '3.4'
    # bigdecimal is not part of the default gems starting from Ruby 3.4.0.
    # csv is not part of the default gems starting from Ruby 3.4.0.
    dependencies.push('bigdecimal')
    dependencies.push('csv')

    # The macOS and Homebrew versions of rubygems have incompatible
    # requirements for sqlite3.
    #
    # macOS 15.5 (Sequoia) comes with version 1.3.13, so it does not
    # need to be added as a dependency, and it cannot install anything
    # newer:
    #
    # requires Ruby version >= 3.0, < 3.4.dev. The current ruby version is 2.6.10.
    #
    # Homebrew's Ruby formula does not come with sqlite3, so it does
    # need to be added as a dependency, but it cannot install version
    # 1.3.13:
    #
    # error: call to undeclared function
    #
    # So neither environment can install the other's sqlite3 gem.  We
    # must install sqlite3, but iff we are not building with macOS'
    # Ruby installation.
    dependencies.push('sqlite3') 
  end

  di = Gem::DependencyInstaller.new(install_dir: gemdir)
  dependencies.each { |d| di.install(d) }
rescue Exception => e
  exit(1)
end 

File.write("Makefile", "clean:\n\ttrue\ninstall:\n\ttrue")

exit(0)
