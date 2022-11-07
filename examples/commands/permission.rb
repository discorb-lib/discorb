# frozen_string_literal: true

require "discorb"

client = Discorb::Client.new

client.once :standby do
  puts "Logged in as #{client.user}"
end

client.slash(
  "admin",
  "You can run this command if you have Administrator permission",
  dm_permission: false,
  default_permission: Discorb::Permission.from_keys(:administrator)
) { |interaction, _name| interaction.post("Hello, admin!") }

client.run(ENV.fetch("DISCORD_BOT_TOKEN", nil))
