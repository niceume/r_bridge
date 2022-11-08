require "r_bridge/version"

require 'r_bridge/r_bridge_ffi'
require 'r_bridge/r_bridge_lazyfunc_ext'

module RBridge
  class Error < StandardError; end
  # Your code goes here...

  if ENV["R_HOME"].nil?
    puts "Environment variable R_HOME is not set." 
    puts "This time, it is tried to be set by 'R RHOME' command."
    begin
      `R --version`
    rescue => e
      puts "R command is not available. Please ensure that your PATH environment variable includes the location of R command."
      raise e
    end

    r_home_output = `R RHOME`
    r_home = r_home_output.chomp
    ENV["R_HOME"] = r_home
    puts "R_HOME environment variable is set to be #{r_home}."
  end
end

