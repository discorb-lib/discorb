require "discorb"
intents = Discorb::Intents.new
intents.members = true
client = Discorb::Client.new(intents: intents, log: $stdout, colorize_log: true)

def convert_role(guild, string)
  guild.roles.find do |role|
    role.id == string || role.name == string || role.mention == string
  end
end

client.once :standby do
  puts "Logged in as #{client.user}"
end

client.on :reaction_add do |event|
  next unless event.emoji.value.end_with?(0x0000fe0f.chr("utf-8") + 0x000020e3.chr("utf-8"))
  next if event.member.bot?

  msg = event.fetch_message.wait
  if msg.embeds.length.positive? && msg.embeds[0].title == "Role panel" && msg.author == client.user
    role_ids = msg.embeds[0].description.scan(/(?<=<@&)\d+(?=>)/)

    role = event.guild.roles[role_ids[event.emoji.value[0].to_i - 1]]
    next if role.nil?

    event.member.add_role(role)
  end
end

client.on :reaction_remove do |event|
  next unless event.emoji.value.end_with?(0x0000fe0f.chr("utf-8") + 0x000020e3.chr("utf-8"))
  next if event.member.bot?

  msg = event.fetch_message.wait
  if msg.embeds.length.positive? && msg.embeds[0].title == "Role panel" && msg.author == client.user
    role_ids = msg.embeds[0].description.scan(/(?<=<@&)\d+(?=>)/)

    role = event.guild.roles[role_ids[event.emoji.value[0].to_i - 1]]
    next if role.nil?

    event.member.remove_role(role)
  end
end

client.on :message do |message|
  next unless message.content.start_with?("/rp ")
  next if message.author.bot?

  message.reply("Too many roles.") if message.content.split.length > 10
  roles = message.content.delete_prefix("/rp ").split.map.with_index { |raw_role, index| [index, convert_role(message.guild, raw_role), raw_role] }
  if (convert_fails = roles.filter { |r| r[1].nil? }).length.positive?
    message.reply("#{convert_fails.map { |r| r[2] }.join(", ")} is not a role.")
    next
  end
  rp_msg = message.channel.post(embed: Discorb::Embed.new(
                                  "Role panel",
                                  roles.map.with_index(1) { |r, index| "#{index}\ufe0f\u20e3#{r[1].mention}" }.join("\n")
                                )).wait
  1.upto(roles.length).each do |i|
    rp_msg.add_reaction(Discorb::UnicodeEmoji["#{i}\ufe0f\u20e3"]).wait
  end
end

client.run(ENV["DISCORD_BOT_TOKEN"])
