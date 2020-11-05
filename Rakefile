require "bundler/gem_tasks"
require "rake/testtask"
require 'rake/clean'

message_for_rake_compiler = "This gem requires native extension compilation. rake-compiler gem should be installed and 'rake compile' before 'rake test'."

begin
  require "rake/extensiontask"
rescue LoadError => e
  puts "ERROR:" + message_for_rake_compiler
  raise
end
raise ("ERROR:" + message_for_rake_compiler) unless defined? Rake::ExtensionTask

# rake compile
Rake::ExtensionTask.new do |ext|
  ext.name = "librbridge" # This should be same as shared library name specified in create_makefile of extconf.rb
  ext.ext_dir = "ext/r_bridge"
  ext.lib_dir = "lib/r_bridge"
end

# rake test
Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

# rake example
task :example do
  file_list = Dir.glob("example/example*.rb")
  file_list.each(){|path|
    puts "###### Running script #{path} #####"
    ruby path
    puts ""
  }
end

# rake clean
CLEAN.include(["tmp/", "lib/r_bridge/librbridge.so"])


task :default => :test
task :test => :compile
