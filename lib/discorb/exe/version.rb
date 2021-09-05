# description: Show information of your environment.

require "etc"
require "discorb"
puts "Ruby: #{RUBY_VERSION}"
puts "discorb: #{Discorb::VERISON}"
uname = Etc.uname
puts "System: #{uname[:sysname]} #{uname[:release]}"
