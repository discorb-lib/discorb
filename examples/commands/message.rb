# frozen_string_literal: true

require "discorb"
require "json"

localizations = {
  context_command: {
    not_found: {
      en: "Bookmark channel not found. Please create one called `bookmarks`.",
      ja: "ブックマークチャンネルが見付かりませんでした。`bookmarks`という名前のチャンネルを作成してください。"
    },
    done: {
      en: "Bookmark added.",
      ja: "ブックマークを追加しました。"
    }
  }
}

client = Discorb::Client.new

client.once :standby do
  puts "Logged in as #{client.user}"
end

def bookmark_channel(guild)
  guild.text_channels.find { |c| c.name == "bookmarks" }
end

def build_embed_from_message(message)
  embed = Discorb::Embed.new
  embed.description = message.content
  embed.author =
    Discorb::Embed::Author.new(
      message.author.to_s,
      icon: message.author.avatar.url
    )
  embed.timestamp = message.timestamp
  embed.footer = Discorb::Embed::Footer.new("ID: #{message.id}")
  embed
end

client.message_command(
  { default: "Bookmark", ja: "ブックマーク" }
) do |interaction, message|
  next unless interaction.guild

  unless channel = bookmark_channel(interaction.guild)
    interaction.post(
      localizations[:context_command][:not_found][interaction.locale] ||
        localizations[:context_command][:not_found][:en],
      ephemeral: true
    )
    next
  end
  channel.post(message.jump_url, embed: build_embed_from_message(message)).wait
  interaction.post(
    localizations[:context_command][:done][interaction.locale] ||
      localizations[:context_command][:done][:en],
    ephemeral: true
  )
end

client.change_presence(
  Discorb::Activity.new("Open message context menu to bookmark")
)

client.run(ENV.fetch("DISCORD_BOT_TOKEN", nil))
