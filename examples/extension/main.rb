# frozen_string_literal: true

require "discorb"
require_relative "message_expander"

intents = Discorb::Intents.new
intents.members = true
intents.message_content = true

client = Discorb::Client.new(intents:)

client.once :standby do
  puts "Logged in as #{client.user}"
end

client.load_extension(MessageExpander)

client.run(ENV.fetch("DISCORD_BOT_TOKEN", nil))
