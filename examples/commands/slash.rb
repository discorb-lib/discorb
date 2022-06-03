# frozen_string_literal: true

require "discorb"

client = Discorb::Client.new

localizations = {
  localized: {
    text: {
      en: "Hello, %s!",
      ja: "%sさん、こんにちは！",
    },
  },
}

client.once :standby do
  puts "Logged in as #{client.user}"
end

client.slash(
  {
    default: "greet",
    ja: "挨拶",
  }, {
    default: "Bot greets. Cute OwO",
    ja: "Botが挨拶します。かわいいね",
  }, {
    "name" => {
      name_localizations: {
        ja: "名前",
      },
      description: {
        default: "The name to greet.",
        ja: "挨拶する人の名前。",
      },
      type: :string,
      optional: true,
    },
  }
) do |interaction, name|
  interaction.post(
    format((localizations[:localized][:text][interaction.locale] || localizations[:localized][:text][:en]),
           name || interaction.user.to_s),
    ephemeral: true,
  )
end

client.run(ENV.fetch("DISCORD_BOT_TOKEN", nil))
