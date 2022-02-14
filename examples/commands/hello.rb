# frozen_string_literal: true
require "discorb"

client = Discorb::Client.new

client.slash("hello", "Greet for you") do |interaction|
  interaction.post("Hello!", ephemeral: true)
end

client.run(ENV["DISCORD_BOT_TOKEN"])
