# require "discorb"
require_relative "../lib/discorb"

client = Discorb::Client.new()

client.on :ready do |task|
  puts "Logged in as #{client.user}"
end

client.on :message do |task, message|
  if message.author.bot?
    return
  end
  if message.content == "!ping"
    message.channel.send "Pong!"
  end
end

client.run(ENV["DISCORD_BOT_TOKEN"])
