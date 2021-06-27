# require "discorb"
require_relative "../lib/discorb"

client = Discorb::Client.new(log: STDOUT, colorize_log: true, log_level: :info)

client.on :ready do |task|
  puts "Logged in as #{client.user}"
end

client.on :message do |task, message|
  p message
  if message.author.bot?
    next
  elsif not message.content.start_with? "!"
    next
  end

  case message.content[1..]
  when "ping"
    message.channel.post "Pong!"
  when "emtest"
    msg = message.channel.post(embed: Discorb::Embed.new("Embed Test", "てすとだよん")).wait
  when /eval [\s\S+]/
    code = message.content.delete_prefix("!eval ").delete_prefix("```rb").delete_suffix("```")
    res = eval(code)
    message.add_reaction(Discorb::UnicodeEmoji["white_check_mark"])
    if res != nil
      message.channel.post(res)
    end
  when "react"
    message.add_reaction(Discorb::UnicodeEmoji["white_check_mark"])
  end
end

client.update_presence(Discorb::PresenceRequest.new("開発"))
client.run(ENV["DISCORD_BOT_TOKEN"])
