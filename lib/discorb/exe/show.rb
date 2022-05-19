# frozen_string_literal: true

# description: Show information of your environment.

require "etc"
require "discorb"

puts "\e[90m    Ruby:\e[m #{RUBY_VERSION}"
puts "\e[90m discorb:\e[m #{Discorb::VERSION}"
uname = Etc.uname
puts "\e[90m  System:\e[m #{uname[:sysname]} #{uname[:release]}"
puts "\e[90mPlatform:\e[m #{RUBY_PLATFORM}"
