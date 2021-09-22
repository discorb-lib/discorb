require "discorb"
require "json"

client = Discorb::Client.new

client.once :standby do
  puts "Logged in as #{client.user}"
end

def bookmark_channel(guild)
  guild.channels.find { |c| c.is_a?(Discorb::TextChannel) && c.name == "bookmarks" }
end

def build_embed_from_message(message)
  embed = Discorb::Embed.new
  embed.description = message.content
  embed.author = Discorb::Embed::Author.new(message.author.to_s_user, icon: message.author.avatar.url)
  embed.timestamp = message.timestamp
  embed.footer = Discorb::Embed::Footer.new("Message ID: #{message.id}")
  embed
end

client.message_command("Bookmark", guild_ids: [857373681096327180]) do |interaction, message|
  unless channel = bookmark_channel(interaction.guild)
    interaction.post("Bookmark channel not found. Please create one called `bookmarks`.", ephemeral: true)
    next
  end
  channel.post(
    message.jump_url,
    embed: build_embed_from_message(message),
  ).wait
  interaction.post("Bookmarked!", ephemeral: true)
end

client.change_presence(
  Discorb::Activity.new(
    "Open message context menu to bookmark"
  )
)

client.run(ENV["DISCORD_BOT_TOKEN"])
