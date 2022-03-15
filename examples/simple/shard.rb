# frozen_string_literal: true
require "discorb"

client = Discorb::Client.new

client.once :standby do
  puts "Logged in as #{client.user}"
end

client.on :message do |message|
  next if message.author.bot?
  next unless message.content == "!inspect"

  message.channel.post("I'm #{client.user}, running on shard #{client.shard_id}!")
end

client.run(ENV["DISCORD_BOT_TOKEN"], shards: [0, 1], shard_count: 2)
