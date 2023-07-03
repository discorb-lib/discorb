# frozen_string_literal: true

require "discorb"

intents = Discorb::Intents.new
intents.message_content = true

client = Discorb::Client.new(intents:)

client.once :standby do
  puts "Logged in as #{client.user}"
end

client.on :message do |message|
  next if message.author.bot?
  next unless message.content.start_with?("eval ")

  unless message.author.bot_owner?.wait
    message.reply("You don't have permission to use this command.")
    next
  end

  code =
    message
      .content
      .delete_prefix("eval ")
      .delete_prefix("```rb")
      .delete_suffix("```")
  message.add_reaction(Discorb::UnicodeEmoji["clock3"])
  res = eval("Async { |task| #{code} }.wait", binding, __FILE__, __LINE__) # rubocop:disable Security/Eval
  message.remove_reaction(Discorb::UnicodeEmoji["clock3"])
  message.add_reaction(Discorb::UnicodeEmoji["white_check_mark"])
  unless res.nil?
    res = res.wait if res.is_a? Async::Task
    message.channel.post("```rb\n#{res.inspect[...1990]}\n```")
  end
rescue Exception => e # rubocop:disable Lint/RescueException
  message.reply embed:
                  Discorb::Embed.new(
                    "Error!",
                    "```rb\n#{e.full_message(highlight: false)[...1990]}\n```",
                    color: Discorb::Color[:red]
                  )
end

client.run(ENV.fetch("discord_bot_token", nil))
