require "discorb"

client = Discorb::Client.new

client.once :standby do
  puts "Logged in as #{client.user}"
end

client.user_command("Info", guild_ids: [857373681096327180]) do |interaction|
  interaction.post(embed: Discorb::Embed.new(
                     "Information of #{interaction.target.to_s_user}",
                     fields: [
                       Discorb::Embed::Field.new("User", interaction.target.to_s_user),
                       Discorb::Embed::Field.new("ID", interaction.target.id),
                       Discorb::Embed::Field.new("Bot", interaction.target.bot? ? "Yes" : "No"),
                       Discorb::Embed::Field.new("Joined at", interaction.target.joined_at.to_df("F")),
                       Discorb::Embed::Field.new("Created at", interaction.target.created_at.to_df("F")),
                     ],
                     thumbnail: interaction.target.avatar&.url,

                   ), ephemeral: true)
end

client.run(ENV["DISCORD_BOT_TOKEN"])
