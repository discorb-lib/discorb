# frozen_string_literal: true

require "discorb"

client = Discorb::Client.new

client.once :standby do
  puts "Logged in as #{client.user}"
end

client.slash(
  "auth",
  "Send authorization button",
  { role: { description: "The role to give.", type: :role, required: true } }
) do |interaction|
  message.channel.post(
    "Click this button if you are human:",
    components: [
      Discorb::Button.new("Get role", custom_id: "auth:#{interaction.id}")
    ]
  )
end

client.on :button_click do |response|
  if response.custom_id.start_with?("auth:")
    id = response.custom_id.delete_prefix("auth:")
    response.user.add_role(id).wait
    response.post(
      "You got your role!\nHere's your role: <@&#{id}>",
      ephemeral: true
    )
  end
end

client.run(ENV.fetch("DISCORD_BOT_TOKEN", nil))
