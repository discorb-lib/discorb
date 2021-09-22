require "discorb"

client = Discorb::Client.new

client.once :standby do
  puts "Logged in as #{client.user}"
end

client.on :message do |message|
  next if message.author.bot?
  next unless message.content == "!quiz"

  operator = [:+, :-, :*].sample
  num1 = rand(1..10)
  num2 = rand(1..10)

  val = num1.send(operator, num2)
  message.channel.post("Quiz: `#{num1} #{operator} #{num2}`")
  begin
    msg = client.event_lock(:message, 30) { |m|
      m.content == val.to_s && m.channel == message.channel
    }.wait
  rescue Discorb::TimeoutError
    message.channel.post("No one answered...")
  else
    msg.reply("Correct!")
  end
end

client.run(ENV["DISCORD_BOT_TOKEN"])
