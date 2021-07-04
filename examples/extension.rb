# frozen_string_literal: true

require_relative '../lib/discorb'

module DispanderForRuby
  extend Discorb::Extension

  @message_regex = Regexp.new(
    '(?!<)https://(?:ptb\.|canary\.)?discord(?:app)?\.com/channels/' \
    '(?<guild>[0-9]{18})/(?<channel>[0-9]{18})/(?<message>[0-9]{18})(?!>)'
  )

  event :message do |_task, message|
    next if message.author.bot?

    message.content.to_enum(:scan, @message_regex).map { Regexp.last_match }.each do |match|
      ch = @client.channels[match[:channel]]
      ic ch
      next if ch.nil?

      begin
        url_message = ch.fetch_message(match[:message]).wait
      rescue Discorb::NotFoundError
        url_message.add_reaction(Discorb::UnicodeEmoji['x'])
      else
        embed = Discorb::Embed.new(
          nil, url_message.content,
          color: Discorb::Color[:blurple],
          timestamp: url_message.created_at,
          author: Discorb::Embed::Author.new(
            url_message.author.name,
            url: url_message.jump_url,
            icon: url_message.author.display_avatar.url
          ),
          footer: Discorb::Embed::Footer.new(
            "#{url_message.guild.name} / #{ch.name}",
            icon: url_message.guild.icon&.url
          )
        )
        message.reply embed: embed
      end
    end
  end
end

client = Discorb::Client.new(log: $stdout, colorize_log: true)

client.extend(DispanderForRuby)

client.run(ENV['discord_bot_token'])
