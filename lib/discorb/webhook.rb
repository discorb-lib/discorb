# frozen_string_literal: true

module Discorb
  #
  # Represents a webhook.
  # @abstract
  #
  class Webhook
    # @return [String] The name of the webhook.
    attr_reader :name
    # @return [Discorb::Snowflake] The ID of the guild this webhook belongs to.
    attr_reader :guild_id
    # @return [Discorb::Snowflake] The ID of the channel this webhook belongs to.
    attr_reader :channel_id
    # @return [Discorb::User] The user that created this webhook.
    attr_reader :user
    # @return [Discorb::Asset] The avatar of the webhook.
    attr_reader :avatar
    # @return [Discorb::Snowflake] The application ID of the webhook.
    # @return [nil] If the webhook is not an application webhook.
    attr_reader :application_id
    # @return [String] The URL of the webhook.
    attr_reader :token

    # @!visibility private
    def initialize(client, data)
      @name = data[:name]
      @guild_id = data[:guild_id] && Snowflake.new(data[:guild_id])
      @channel_id = Snowflake.new(data[:channel_id])
      @id = Snowflake.new(data[:id])
      @user = data[:user]
      @name = data[:name]
      @avatar = Asset.new(self, data[:avatar])
      @token = ""
      @application_id = data[:application_id]
      @client = client
      @http = Discorb::HTTP.new(client)
    end

    def inspect
      "#<#{self.class} #{@name.inspect} id=#{@id}>"
    end

    #
    # Posts a message to the webhook.
    # @macro async
    # @macro http
    #
    # @param [String] content The content of the message.
    # @param [Boolean] tts Whether the message should be sent as text-to-speech.
    # @param [Discorb::Embed] embed The embed to send.
    # @param [Array<Discorb::Embed>] embeds The embeds to send.
    # @param [Discorb::AllowedMentions] allowed_mentions The allowed mentions to send.
    # @param [Discorb::File] file The file to send.
    # @param [Array<Discorb::File>] files The files to send.
    # @param [String] username The username of the message.
    # @param [String] avatar_url The avatar URL of the message.
    # @param [Boolean] wait Whether to wait for the message to be sent.
    #
    # @return [Discorb::Webhook::Message] The message that was sent.
    # @return [Async::Task<nil>] If `wait` is false.
    #
    def post(content = nil, tts: false, embed: nil, embeds: nil, allowed_mentions: nil,
                            file: nil, files: nil, username: nil, avatar_url: :unset, wait: true)
      Async do
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
          headers, payload = HTTP.multipart(payload, files)
        else
          headers = {
            "Content-Type" => "application/json",
          }
        end
        _resp, data = @http.post("#{url}?wait=#{wait}", payload, headers: headers).wait

        data && Webhook::Message.new(self, data)
      end
    end

    alias execute post

    #
    # Edits the webhook.
    # @macro async
    # @macro http
    # @macro edit
    #
    # @param [String] name The new name of the webhook.
    # @param [Discorb::Image] avatar The new avatar of the webhook.
    # @param [Discorb::GuildChannel] channel The new channel of the webhook.
    #
    def edit(name: :unset, avatar: :unset, channel: :unset)
      Async do
        payload = {}
        payload[:name] = name if name != :unset
        payload[:avatar] = avatar if avatar != :unset
        payload[:channel_id] = Utils.try(channel, :id) if channel != :unset
        @http.patch(url.to_s, payload).wait
      end
    end

    alias modify edit

    #
    # Deletes the webhook.
    # @macro async
    # @macro http
    #
    def delete!
      Async do
        @http.delete(url).wait
        self
      end
    end

    alias destroy! delete!

    #
    # Edits the webhook's message.
    # @macro async
    # @macro http
    # @macro edit
    #
    # @param [Discorb::Webhook::Message] message The message to edit.
    # @param [String] content The new content of the message.
    # @param [Discorb::Embed] embed The new embed of the message.
    # @param [Array<Discorb::Embed>] embeds The new embeds of the message.
    # @param [Array<Discorb::Attachment>] attachments The attachments to remain.
    # @param [Discorb::File] file The file to send.
    # @param [Array<Discorb::File>] files The files to send.
    # @param [Discorb::AllowedMentions] allowed_mentions The allowed mentions to send.
    #
    def edit_message(
      message, content = :unset,
      embed: :unset, embeds: :unset,
      file: :unset, files: :unset,
      attachments: :unset,
      allowed_mentions: :unset
    )
      Async do
        payload = {}
        payload[:content] = content if content != :unset
        payload[:embeds] = embed ? [embed.to_hash] : [] if embed != :unset
        payload[:embeds] = embeds.map(&:to_hash) if embeds != :unset
        payload[:attachments] = attachments.map(&:to_hash) if attachments != :unset
        payload[:allowed_mentions] = allowed_mentions if allowed_mentions != :unset
        files = [file] if file != :unset
        if files == :unset
          headers = {
            "Content-Type" => "application/json",
          }
        else
          headers, payload = HTTP.multipart(payload, files)
        end
        _resp, data = @http.patch("#{url}/messages/#{Utils.try(message, :id)}", payload, headers: headers).wait
        message.send(:_set_data, data)
        message
      end
    end

    #
    # Deletes the webhook's message.
    #
    # @param [Discorb::Webhook::Message] message The message to delete.
    #
    def delete_message!(message)
      Async do
        @http.delete("#{url}/messages/#{Utils.try(message, :id)}").wait
        message
      end
    end

    #
    # Represents a webhook from URL.
    #
    class URLWebhook < Webhook
      # @return [String] The URL of the webhook.
      attr_reader :url

      #
      # Initializes the webhook from URL.
      #
      # @param [String] url The URL of the webhook.
      #
      def initialize(url)
        @url = url
        @token = ""
        @http = Discorb::HTTP.new(self)
      end
    end

    #
    # Represents a bot created webhook.
    #
    class IncomingWebhook < Webhook
      # @!attribute [r] url
      #   @return [String] The URL of the webhook.

      # @!visibility private
      def initialize(client, data)
        super
        @token = data[:token]
      end

      def url
        "https://discord.com/api/v9/webhooks/#{@id}/#{@token}"
      end
    end

    #
    # Represents a webhook of channel following.
    #
    class FollowerWebhook < Webhook
      # @!attribute [r] source_guild
      #   Represents a source guild of follower webhook.
      #   @return [Discorb::Guild, Discorb::Webhook::FollowerWebhook::Guild] The source guild of follower webhook.
      # @!attribute [r] source_channel
      #   Represents a source channel of follower webhook.
      #   @return [Discorb::Channel, Discorb::Webhook::FollowerWebhook::Channel] The source channel of follower webhook.

      # @!visibility private
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

      #
      # Represents a guild of follower webhook.
      #
      class Guild < DiscordModel
        # @return [Discorb::Snowflake] The ID of the guild.
        attr_reader :id
        # @return [String] The name of the guild.
        attr_reader :name
        # @return [Discorb::Asset] The icon of the guild.
        attr_reader :icon

        # @!visibility private
        def initialize(data)
          @id = Snowflake.new(data[:id])
          @name = data[:name]
          @icon = Asset.new(self, data[:icon])
        end
      end

      #
      # Represents a channel of follower webhook.
      #
      class Channel < DiscordModel
        # @return [Discorb::Snowflake] The ID of the channel.
        attr_reader :id
        # @return [String] The name of the channel.
        attr_reader :name

        # @!visibility private
        def initialize(data)
          @id = Snowflake.new(data[:id])
          @name = data[:name]
        end
      end
    end

    #
    # Represents a webhook from oauth2.
    #
    class ApplicationWebhook < Webhook
    end

    # private

    #
    # Represents a webhook message.
    #
    class Message < Discorb::Message
      # @return [Discorb::Snowflake] The ID of the channel.
      attr_reader :channel_id
      # @return [Discorb::Snowflake] The ID of the guild.
      attr_reader :guild_id

      # @!visibility private
      def initialize(webhook, data, client = nil)
        @client = client
        @webhook = webhook
        @data = data
        _set_data(data)
      end

      #
      # Edits the message.
      # @macro async
      # @macro http
      # @macro edit
      #
      # @param (see Webhook#edit_message)
      #
      def edit(...)
        Async do
          @webhook.edit_message(self, ...).wait
        end
      end

      #
      # Deletes the message.
      # @macro async
      # @macro http
      #
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

      #
      # Represents an author of webhook message.
      #
      class Author < DiscordModel
        # @return [Boolean] Whether the author is a bot.
        # @note This will be always `true`.
        attr_reader :bot
        alias bot? bot
        # @return [Discorb::Snowflake] The ID of the author.
        attr_reader :id
        # @return [String] The name of the author.
        attr_reader :username
        alias name username
        # @return [Discorb::Asset] The avatar of the author.
        attr_reader :avatar
        # @return [String] The discriminator of the author.
        attr_reader :discriminator

        # @!visibility private
        def initialize(data)
          @data = data
          @bot = data[:bot]
          @id = Snowflake.new(data[:id])
          @username = data[:username]
          @avatar = data[:avatar] ? Asset.new(self, data[:avatar]) : DefaultAvatar.new(data[:discriminator])
          @discriminator = data[:discriminator]
        end

        #
        # Format author with `Name#Discriminator` style.
        #
        # @return [String] Formatted author.
        #
        def to_s
          "#{@username}##{@discriminator}"
        end

        alias to_s_user to_s
      end
    end

    class << self
      #
      # Creates URLWebhook.
      #
      # @param [String] url The URL of the webhook.
      #
      # @return [Discorb::Webhook::URLWebhook] The URLWebhook.
      #
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
