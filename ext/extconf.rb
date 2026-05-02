begin
  require 'rubygems/dependency_installer'

  # Install dependencies that are not already installed
  stubs = Gem::Specification.stubs.map(&:name)

  dependencies = %w[ plist logger csv json open3 rdoc sqlite3 yaml ]
  dependencies.reject! { |d| stubs.include?(d) }

  unless dependencies.empty?
    di = Gem::DependencyInstaller.new
    dependencies.each { |d| di.install(d) }
  end

rescue Exception => e
  abort(e)
end

exit(0)
