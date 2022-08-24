#!/usr/bin/env ruby
# frozen_string_literal: true

# description: Connect to discord and start IRB.

require "io/console"
require "discorb"
require "optparse"

intents_value = Discorb::Intents.all.value
token_file = "token"

opt = OptionParser.new <<~BANNER
                         This command will start an interactive Ruby shell with connected client.

                         Usage: discorb irb [options]
                       BANNER
opt.on("-i", "--intents", "intents to use, default to all") do |v|
  intents_value = v
end
opt.on("-t", "--token-file", "token file to load, default to \"token\"") do |v|
  token_file = v
end
opt.parse!(ARGV)

client =
  Discorb::Client.new(intents: Discorb::Intents.from_value(intents_value))
$messages = []

client.on :standby do
  puts "\e[96mLogged in as #{client.user}\e[m"

  def message
    $messages.last
  end

  def dirb_help
    puts <<~MESSAGE
           \e[96mDiscord-IRB\e[m
           This is a debug client for Discord.
           \e[90mmessage\e[m to get latest message.

           \e[36mhttps://discorb-lib.github.io/#{Discorb::VERSION}/file.irb.html\e[m for more information.
         MESSAGE
  end

  puts <<~FIRST_MESSAGE
         Running on \e[31mRuby #{RUBY_VERSION}\e[m, disco\e[31mrb #{Discorb::VERSION}\e[m
    Type \e[90mdirb_help\e[m to help.
       FIRST_MESSAGE

  binding.irb # rubocop:disable Lint/Debugger

  client.close!
end

client.on :message do |message|
  $messages << message
end

token = ENV.fetch("DISCORD_BOT_TOKEN", nil) || ENV.fetch("DISCORD_TOKEN", nil)
if token.nil?
  if File.exist?(token_file)
    token = File.read(token_file)
  else
    print "\e[90mToken?\e[m : "
    token = $stdin.noecho(&:gets).chomp
    puts
  end
end

client.run token
