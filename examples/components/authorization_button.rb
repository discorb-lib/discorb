require "discorb"

client = Discorb::Client.new

def convert_role(guild, string)
  guild.roles.find do |role|
    role.id == string || role.name == string || role.mention == string
  end
end

client.once :standby do
  puts "Logged in as #{client.user}"
end

client.on :message do |message|
  next if message.author.bot?
  next unless message.content.start_with?("!auth ")

  role_name = message.content.delete_prefix("!auth ")
  role = convert_role(message.guild, role_name)
  if role.nil?
    message.reply("Unknown role: #{role_name}").wait
    next
  end
  message.channel.post(
    "Click this button if you are human:",
    components: [
      Discorb::Button.new(
        "Get role", custom_id: "auth:#{role.id}",
      ),
    ],
  )
end

client.on :button_click do |response|
  if response.custom_id.start_with?("auth:")
    id = response.custom_id.delete_prefix("auth:")
    response.fired_by.add_role(id).wait
    response.post("You got your role!\nHere's your role: <@&#{id}>", ephemeral: true)
  end
end

client.run(ENV["DISCORD_BOT_TOKEN"])
