# frozen_string_literal: true

require "discorb"

#
# Class for expanding message URL.
#
class MessageExpander
  include Discorb::Extension

  MESSAGE_PATTERN = Regexp.new(
    '(?!<)https://(?:ptb\.|canary\.)?discord(?:app)?\.com/channels/' \
    "(?<guild>[0-9]{18})/(?<channel>[0-9]{18})/(?<message>[0-9]{18,19})(?!>)"
  )

  event :message do |message|
    next if message.author.bot?

    message.content.to_enum(:scan, MESSAGE_PATTERN).map { Regexp.last_match }.each do |match|
      ch = @client.channels[match[:channel]]
      next if ch.nil?

      begin
        url_message = ch.fetch_message(match[:message]).wait
      rescue Discorb::NotFoundError
        message.add_reaction(Discorb::UnicodeEmoji["x"])
      else
        embed = Discorb::Embed.new(
          nil, url_message.content,
          color: Discorb::Color[:blurple],
          timestamp: url_message.created_at,
          author: Discorb::Embed::Author.new(
            url_message.author.name,
            url: url_message.jump_url,
            icon: url_message.author.avatar.url,
          ),
          footer: Discorb::Embed::Footer.new(
            "#{url_message.guild.name} / #{ch.name}",
            icon: url_message.guild.icon&.url,
          ),
        )
        message.reply embed: embed
      end
    end
  end
end
