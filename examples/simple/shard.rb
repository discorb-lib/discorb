# frozen_string_literal: true

require "discorb"

client = Discorb::Client.new(logger: Logger.new($stderr))

client.once :standby do
  puts "Logged in as #{client.user}"
end

client.slash("inspect", "Inspect about this bot") do |interaction|
  interaction.post("I'm #{client.user}, running on shard #{client.shard_id}!")
end

client.run(ENV.fetch("DISCORD_BOT_TOKEN", nil), shards: [0, 1], shard_count: 2)
