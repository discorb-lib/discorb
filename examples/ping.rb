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
  case message.content
  when "ping"
    message.channel.post "Pong!"
  when "emtest"
    msg = message.channel.post(embed: Discorb::Embed.new("Embed Test", "てすとだよん")).wait
  when /eval [\s\S+]/
    code = message.content.delete_prefix("eval ").delete_prefix("```rb").delete_suffix("```")
    eval(code)
  end
end

client.run(ENV["DISCORD_BOT_TOKEN"])
