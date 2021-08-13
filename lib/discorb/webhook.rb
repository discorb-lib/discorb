# frozen_string_literal: true

require 'async/http/internet'

require_relative 'common'

module Discorb
  class Webhook
    attr_reader :name, :guild_id, :channel_id, :user, :avatar, :application_id, :internet, :token

    def initialize(client, data)
      @name = data[:name]
      @guild_id = data[:guild_id] && Snowflake.new(data[:guild_id])
      @channel_id = Snowflake.new(data[:channel_id])
      @id = Snowflake.new(data[:id])
      @user = data[:user]
      @name = data[:name]
      @avatar = Asset.new(self, data[:avatar])
      @token = ''
      # @token = data[:token]
      @application_id = data[:application_id]
      # @source_guild = data[:source_guild]
      # @source_channel = Snowflake.new(data[:source_channel])
      # @url = data[:url]
      # p data
      @client = client
      @internet = Discorb::Internet.new(client)
    end

    def inspect
      "#<#{self.class} #{@name.inspect} id=#{@id}>"
    end

    def post(content = nil, tts: false, embed: nil, embeds: nil, allowed_mentions: nil,
             file: nil, files: nil, username: nil, avatar_url: :unset, wait: true)
      Async do |_task|
        payload = {}
        payload[:content] = content if content
        payload[:tts] = tts
        tmp_embed = if embed
                      [embed]
                    elsif embeds
                      embeds
                    end
        payload[:embeds] = tmp_embed.map(&:to_hash) if tmp_embed
        payload[:allowed_mentions] = allowed_mentions&.to_hash
        payload[:username] = username if username
        payload[:avatar_url] = avatar_url if avatar_url != :unset
        files = [file] if file
        if files
          headers, payload = Internet.multipart(payload, files)
        else
          headers = {
            'Content-Type' => 'application/json'
          }
        end
        _resp, data = @internet.post("#{url}?wait=#{wait}", payload, headers: headers).wait

        data && Webhook::Message.new(self, data)
      end
    end

    alias execute post

    def edit(name: :unset, avatar: :unset, channel: :unset)
      Async do |_task|
        payload = {}
        payload[:name] = name if name != :unset
        payload[:avatar] = avatar if avatar != :unset
        payload[:channel_id] = Utils.try(channel, :id) if channel != :unset
        @internet.patch(url.to_s, payload).wait
      end
    end

    alias modify edit

    def delete!
      Async do
        @internet.delete(url).wait
        self
      end
    end

    alias destroy! delete!

    def edit_message(
      message, content = :unset,
      embed: :unset, embeds: :unset,
      file: :unset, files: :unset,
      attachment: :unset, attachments: :unset,
      allowed_mentions: :unset
    )
      Async do
        payload = {}
        payload[:content] = content if content != :unset
        payload[:embeds] = embed ? [embed.to_hash] : [] if embed != :unset
        payload[:embeds] = embeds.map(&:to_hash) if embeds != :unset
        attachments = [attachment] if attachment != :unset
        payload[:attachments] = attachments.map(&:to_hash) if attachments != :unset
        payload[:allowed_mentions] = allowed_mentions if allowed_mentions != :unset
        files = [file] if file != :unset
        if files == :unset
          headers = {
            'Content-Type' => 'application/json'
          }
        else
          headers, payload = Internet.multipart(payload, files)
        end
        _resp, data = @internet.patch("#{url}/messages/#{Utils.try(message, :id)}", payload, headers: headers).wait
        message.send(:_set_data, data)
        message
      end
    end

    def delete_message!(message)
      Async do
        @internet.delete("#{url}/messages/#{Utils.try(message, :id)}").wait
        message
      end
    end

    class URLWebhook < Webhook
      attr_reader :url

      def initialize(url)
        @url = url
        @token = ''
        @internet = Discorb::Internet.new(self)
      end
    end

    class IncomingWebhook < Webhook
      def initialize(client, data)
        super
        @token = data[:token]
      end

      def url
        "https://discord.com/api/v9/webhooks/#{@id}/#{@token}"
      end
    end

    class FollowerWebhook < Webhook
      def initialize(client, data)
        super
        @source_guild = FollowerWebhook::Guild.new(data[:source_guild])
        @source_channel = FollowerWebhook::Channel.new(data[:source_channel])
      end

      def source_guild
        @client.guilds[@source_guild.id] || @source_guild
      end

      def source_channel
        @client.channels[@source_channel.id] || @source_channel
      end

      class Guild < DiscordModel
        attr_reader :id, :name, :icon

        def initialize(data)
          @id = Snowflake.new(data[:id])
          @name = data[:name]
          @icon = Asset.new(self, data[:icon])
        end
      end

      class Channel < DiscordModel
        attr_reader :id, :name

        def initialize(data)
          @id = Snowflake.new(data[:id])
          @name = data[:name]
        end
      end
    end

    class ApplicationWebhook < Webhook
    end

    # private

    class Message < Discorb::Message
      attr_reader :channel_id, :guild_id

      def initialize(webhook, data, client = nil)
        @client = client
        @webhook = webhook
        @data = data
        _set_data(data)
      end

      def edit(...)
        Async do
          @webhook.edit_message(self, ...).wait
        end
      end

      def delete!
        Async do
          @webhook.delete_message!(self).wait
        end
      end

      private

      def _set_data(data)
        @id = Snowflake.new(data[:id])
        @type = Discorb::Message.message_type[data[:type]]
        @content = data[:content]
        @channel_id = Snowflake.new(data[:channel_id])
        @author = Author.new(data[:author])
        @attachments = data[:attachments].map { |a| Attachment.new(a) }
        @embeds = data[:embeds] ? data[:embeds].map { |e| Embed.new(data: e) } : []
        @mentions = data[:mentions].map { |m| Mention.new(m) }
        @mention_roles = data[:mention_roles].map { |m| Snowflake.new(m) }
        @mention_everyone = data[:mention_everyone]
        @pinned = data[:pinned]
        @tts = data[:tts]
        @created_at = data[:edited_timestamp] && Time.iso8601(data[:timestamp])
        @updated_at = data[:edited_timestamp] && Time.iso8601(data[:edited_timestamp])
        @flags = Message::Flag.new(data[:flags])
        @webhook_id = Snowflake.new(data[:webhook_id])
      end

      class Author < DiscordModel
        attr_reader :bot, :id, :username, :avatar, :discriminator
        alias name username

        def initialize(data)
          @data = data
          @bot = data[:bot]
          @id = Snowflake.new(data[:id])
          @username = data[:username]
          @avatar = data[:avatar]
          @discriminator = data[:discriminator]
        end
      end
    end

    class << self
      def new(url)
        if self != Webhook
          return super(*url) if url.is_a?(Array)

          return super
        end
        if url.is_a?(String)
          URLWebhook.new(url)
        else
          case url[1][:type]
          when 1
            IncomingWebhook
          when 2
            FollowerWebhook
          when 3
            ApplicationWebhook
          end.new(url)
        end
      end

      def from_url(url)
        URLWebhook.new(url)
      end
    end
  end
end
