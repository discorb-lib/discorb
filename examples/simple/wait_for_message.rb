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
  next unless message.content == "!quiz"

  operator = %i[+ - *].sample
  next unless operator

  num1 = rand(1..10)
  num2 = rand(1..10)

  val = num1.send(operator, num2)
  message.channel.post("Quiz: `#{num1} #{operator} #{num2}`")
  begin
    msg =
      client
        .event_lock(:message, 30) do |m|
          m.content == val.to_s && m.channel == message.channel
        end
        .wait
  rescue Discorb::TimeoutError
    message.channel.post("No one answered...")
  else
    msg.reply("Correct!")
  end
end

client.run(ENV.fetch("DISCORD_BOT_TOKEN", nil))
