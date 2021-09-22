#!/usr/bin/env ruby

# description: Connect to discord and start IRB.

require "io/console"
require "discorb"
require "optparse"

intents_value = Discorb::Intents.all.value
token_file = "token"

ARGV.delete_at 0

opt = OptionParser.new <<~BANNER
                         This command will start an interactive Ruby shell with connected client.

                         Usage: discorb irb [options]
                       BANNER
opt.on("-i", "--intents", "intents to use, default to all") { |v| intents_value = v }
opt.on("-t", "--token-file", "token file to load, default to \"token\"") { |v| token_file = v }
opt.parse!(ARGV)

client = Discorb::Client.new(intents: Discorb::Intents.from_value(intents_value))
$messages = []

client.on :standby do
  puts "\e[96mLogged in as #{client.user}\e[m"

  def message
    $messages.last
  end

  def dirb_help
    puts <<~EOS
           \e[96mDiscord-IRB\e[m
           This is a debug client for Discord.
           \e[90mmessage\e[m to get latest message.

           \e[36mhttps://discorb-lib.github.io/#{Discorb::VERSION}/file.irb.html\e[m for more information.
         EOS
  end

  puts <<~FIRST_MESSAGE
         Running on \e[31mRuby #{RUBY_VERSION}\e[m, disco\e[31mrb #{Discorb::VERSION}\e[m
         Type \e[90mdirb_help\e[m to help.
       FIRST_MESSAGE

  binding.irb

  client.close!
end

client.on :message do |message|
  $messages << message
end

token = ENV["DISCORD_BOT_TOKEN"] || ENV["DISCORD_TOKEN"]
if token.nil?
  if File.exists?(token_file)
    token = File.read(token_file)
  else
    print "\e[90mToken?\e[m : "
    token = $stdin.noecho(&:gets).chomp
    puts
  end
end

client.run token
