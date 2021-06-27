# require "discorb"
require_relative "../lib/discorb"

client = Discorb::Client.new(log: STDOUT, colorize_log: true, log_level: :debug)

client.on :ready do |task|
  puts "Logged in as #{client.user}"
end

client.on :message do |task, message|
  if message.author.bot?
    next
  end
  if message.content == "!ping"
    message.channel.post "Pong!"
  end
end

client.run(ENV["DISCORD_BOT_TOKEN"])
