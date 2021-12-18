# description: Show information of your environment.

require "etc"
require "discorb"

puts "\e[90mRuby:\e[m #{RUBY_VERSION}"
puts "\e[90mdiscorb:\e[m #{Discorb::VERSION}"
uname = Etc.uname
puts "\e[90mSystem:\e[m #{uname[:sysname]} #{uname[:release]}"
puts "\e[90mPlatform:\e[m #{RUBY_PLATFORM}"
