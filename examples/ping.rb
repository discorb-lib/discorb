# require "discorb"
require_relative "../lib/discorb"
require "async"

client = Discorb::Client.new(log: STDOUT, colorize_log: true, log_level: :info, allowed_mentions: Discorb::AllowedMentions.new(replied_user: false))

client.on :ready do |task|
  puts "Logged in as #{client.user}"
end

client.on(:message) do |task, message|
  if message.author.bot?
    next
  elsif not message.content.start_with? "!"
    next
  end

  case message.content[1..]
  when "ping"
    message.channel.post "Pong!"
  when "emtest"
    msg = message.channel.post(embed: Discorb::Embed.new("Embed Test", "I am test")).wait
  when /eval [\s\S+]/
    code = message.content.delete_prefix("!eval ").delete_prefix("`" + "``rb").delete_suffix("`" + "``")
    res = eval(code)
    message.add_reaction(Discorb::UnicodeEmoji["white_check_mark"])
    if res != nil
      if res.is_a? Async::Task
        res = res.wait
      end
      message.channel.post("``" + "`rb\n#{res.inspect[...1990]}\n`" + "``")
    end
  when "react"
    message.add_reaction(Discorb::UnicodeEmoji["white_check_mark"])
  when "reply"
    message.reply "Test"
  end
end.rescue do |task, error, message|
  message.reply embed: Discorb::Embed.new("Error!", "```rb\n#{error.full_message(highlight: false)[...1990]}\n```", color: Discorb::Color[:red])
end

client.update_presence(Discorb::Activity.new("Music", :listening))
client.run(ENV["DISCORD_BOT_TOKEN"])
