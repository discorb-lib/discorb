#!/usr/bin/env ruby
# frozen_string_literal: true

# description: Connect to discord and start IRB.

require "io/console"
require "discorb"
require "dotenv/load"
require "optparse"

options = {
  intents_value: Discorb::Intents.all,
}

OptionParser.new do |opts|
  opts.banner = <<~BANNER
                  This command will start an interactive Ruby shell with connected client.

                  Usage: discorb irb [options]
                BANNER

  opts.accept(Discorb::Intents) do |value|
    Discorb::Intents.from_value(Integer(value))
  end

  opts.on("-i", "--intents=INTENTS", Discorb::Intents, "The intents to use, all will be used if not specified") do |v|
    options[:intents_value] = v
  end

  opts.on("-t", "--token-file=FILE", "The token file to load") do |v|
    options[:token_file] = v
  end
end.parse!

client = Discorb::Client.new(intents: options[:intents_value])

client.on :ready do
  $messages = []

  def message
    $messages.last
  end

  def dirb_help
    puts <<~HELP
           \e[96mDiscord-IRB\e[m
           This is a debug client for Discord.
           Type \e[31mmessage\e[m to get latest message.

           \e[36mhttps://discorb-lib.github.io/#{Discorb::VERSION}/file.irb.html\e[m for more information.
         HELP
  end

  puts "\e[96mLogged in as #{client.user}\e[m"
  puts <<~INFO
         Running on \e[31mRuby #{RUBY_VERSION}\e[m, disco\e[31mrb #{Discorb::VERSION}\e[m
         Type \e[31mdirb_help\e[m to help.
       INFO

  # Begin the user's IRB session
  binding.irb # rubocop:disable Lint/Debugger

  # Assume once the IRB session is over the user is finished.
  client.close
end

client.on :message do |message|
  $messages << message
end

# Prefer to use the token file if the option was given.
if options[:token_file]
  token = File.read(options[:token_file])
else
  token = ENV["DISCORD_BOT_TOKEN"] || ENV["DISCORD_TOKEN"] || ENV["TOKEN"]

  unless token
    print "\e[90mToken?\e[m : "
    token = $stdin.noecho(&:gets).chomp
    puts
  end
end

client.run(token)
