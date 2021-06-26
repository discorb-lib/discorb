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

client.run("ODA0ODE4NjcwOTc0NDAyNTkx.YBR3yw.R_BDW6lnvQQ258KJlt7CVUUw9-k")
