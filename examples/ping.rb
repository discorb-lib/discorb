# frozen_string_literal: true

# require "discorb"
require_relative "../lib/discorb"
require "async"

client = Discorb::Client.new(log: $stdout, colorize_log: true, log_level: :info,
                             allowed_mentions: Discorb::AllowedMentions.new(replied_user: false))

client.on :ready do |_task|
  puts "Logged in as #{client.user}"
end

client.on :message do |_task, message|
  next if message.author.bot?

  next unless message.content.start_with? "!"

  case message.content[1..]
  when "ping"
    message.channel.post "Pong!"
  end
end

client.run(ENV["discord_bot_token"])
