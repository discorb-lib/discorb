# frozen_string_literal: true
require "discorb"

localizations = {
  info: {
    title: {
      en: "%s's info",
      ja: "%sの詳細",
    },
    fields: {
      en: ["Name", "ID", "Bot", "Joined at", "Account created at"],
      ja: %w[名前 ID ボット 参加日時 アカウント作成日時],
    },
    yn: {
      en: %w[Yes No],
      ja: %w[はい いいえ],
    },
  },
}

client = Discorb::Client.new

client.once :standby do
  puts "Logged in as #{client.user}"
end

client.user_command({
  default: "info",
  ja: "詳細",
}) do |interaction|
  field_name = localizations[:info][:fields][interaction.locale] || localizations[:info][:fields][:en]
  interaction.post(
    embed: Discorb::Embed.new(
      format((localizations[:info][:title][interaction.locale] || localizations[:info][:title][:en]), interaction.target.to_s_user),
      fields: [
        Discorb::Embed::Field.new(field_name[0], interaction.target.to_s_user),
        Discorb::Embed::Field.new(field_name[1], interaction.target.id),
        Discorb::Embed::Field.new(
          field_name[2],
          (localizations[:info][:yn][interaction.locale] || localizations[:info][:yn][:en])[interaction.target.bot? ? 0 : 1]
        ),
        Discorb::Embed::Field.new(field_name[3], interaction.target.joined_at.to_df("F")),
        Discorb::Embed::Field.new(field_name[4], interaction.target.created_at.to_df("F")),
      ],
      thumbnail: interaction.target.avatar&.url,

    ), ephemeral: true,
  )
end

client.run(ENV.fetch("DISCORD_BOT_TOKEN", nil))
