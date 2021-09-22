require "discorb"
require_relative "message_expander"

client = Discorb::Client.new

client.once :standby do
  puts "Logged in as #{client.user}"
end

client.extend(MessageExpander)

client.run(ENV["DISCORD_BOT_TOKEN"])
