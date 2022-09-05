# frozen_string_literal: true

require "discorb"

client = Discorb::Client.new

client.once :standby do
  puts "Logged in as #{client.user}"
end

client.slash("ping", "Ping!") do |interaction|
  interaction.post("Pong!", ephemeral: true)
end

client.run(ENV.fetch("DISCORD_BOT_TOKEN", nil))
