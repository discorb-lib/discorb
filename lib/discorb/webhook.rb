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

    #
    # Initializes a webhook.
    # @private
    #
    # @param [Discorb::Client] client The client.
    # @param [Hash] data The data of the webhook.
    #
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
    # @async
    #
    # @param [String] content The content of the message.
    # @param [Boolean] tts Whether the message should be sent as text-to-speech.
    # @param [Discorb::Embed] embed The embed to send.
    # @param [Array<Discorb::Embed>] embeds The embeds to send.
    # @param [Discorb::AllowedMentions] allowed_mentions The allowed mentions to send.
    # @param [Discorb::Attachment] attachment The attachment to send.
    # @param [Array<Discorb::Attachment>] attachment The attachments to send.
    # @param [String] username The username of the message.
    # @param [String] avatar_url The avatar URL of the message.
    # @param [Boolean] wait Whether to wait for the message to be sent.
    #
    # @return [Discorb::Webhook::Message] The message that was sent.
    # @return [Async::Task<nil>] If `wait` is false.
    #
    def post(
      content = nil,
      tts: false,
      embed: nil,
      embeds: nil,
      allowed_mentions: nil,
      attachment: nil,
      attachments: nil,
      username: nil,
      avatar_url: Discorb::Unset,
      wait: true
    )
      Async do
        payload = {}
        payload[:content] = content if content
        payload[:tts] = tts
        tmp_embed =
          if embed
            [embed]
          elsif embeds
            embeds
          end
        payload[:embeds] = tmp_embed.map(&:to_hash) if tmp_embed
        payload[:allowed_mentions] = allowed_mentions&.to_hash
        payload[:username] = username if username
        payload[:avatar_url] = avatar_url if avatar_url != Discorb::Unset
        attachments = [attachment] if attachment
        _resp, data =
          @http.multipart_request(
            Route.new(
              "#{url}?wait=#{wait}",
              "//webhooks/:webhook_id/:token",
              :post
            ),
            attachments,
            payload
          ).wait
        data && Webhook::Message.new(self, data)
      end
    end

    alias execute post

    #
    # Edits the webhook.
    # @async
    # @macro edit
    #
    # @param [String] name The new name of the webhook.
    # @param [Discorb::Image] avatar The new avatar of the webhook.
    # @param [Discorb::GuildChannel] channel The new channel of the webhook.
    #
    # @return [Async::Task<void>] The task.
    #
    def edit(
      name: Discorb::Unset,
      avatar: Discorb::Unset,
      channel: Discorb::Unset
    )
      Async do
        payload = {}
        payload[:name] = name if name != Discorb::Unset
        payload[:avatar] = avatar if avatar != Discorb::Unset
        payload[:channel_id] = Utils.try(channel, :id) if channel !=
          Discorb::Unset
        @http.request(
          Route.new(url, "//webhooks/:webhook_id/:token", :patch),
          payload
        ).wait
      end
    end

    alias modify edit

    #
    # Deletes the webhook.
    # @async
    #
    # @return [Async::Task<void>] The task.
    #
    def delete
      Async do
        @http.request(
          Route.new(url, "//webhooks/:webhook_id/:token", :delete)
        ).wait
        self
      end
    end

    alias destroy delete

    #
    # Edits the webhook's message.
    # @async
    # @macro edit
    #
    # @param [Discorb::Webhook::Message] message The message to edit.
    # @param [String] content The new content of the message.
    # @param [Discorb::Embed] embed The new embed of the message.
    # @param [Array<Discorb::Embed>] embeds The new embeds of the message.
    # @param [Array<Discorb::Attachment>] attachments The attachments to remain.
    # @param [Discorb::Attachment] file The file to send.
    # @param [Array<Discorb::Attachment>] files The files to send.
    # @param [Discorb::AllowedMentions] allowed_mentions The allowed mentions to send.
    #
    # @return [Async::Task<void>] The task.
    #
    def edit_message(
      message,
      content = Discorb::Unset,
      embed: Discorb::Unset,
      embeds: Discorb::Unset,
      file: Discorb::Unset,
      files: Discorb::Unset,
      attachments: Discorb::Unset,
      allowed_mentions: Discorb::Unset
    )
      Async do
        payload = {}
        payload[:content] = content if content != Discorb::Unset
        payload[:embeds] = embed ? [embed.to_hash] : [] if embed !=
          Discorb::Unset
        payload[:embeds] = embeds.map(&:to_hash) if embeds != Discorb::Unset
        payload[:attachments] = attachments.map(&:to_hash) if attachments !=
          Discorb::Unset
        payload[:allowed_mentions] = allowed_mentions if allowed_mentions !=
          Discorb::Unset
        files = [file] if file != Discorb::Unset
        _resp, data =
          @http.multipart_request(
            Route.new(
              "#{url}/messages/#{Utils.try(message, :id)}",
              "//webhooks/:webhook_id/:token/messages/:message_id",
              :patch
            ),
            payload,
            files
          ).wait
        message.send(:_set_data, data)
        message
      end
    end

    #
    # Deletes the webhook's message.
    #
    # @param [Discorb::Webhook::Message] message The message to delete.
    #
    # @return [Async::Task<void>] The task.
    #
    def delete_message(message)
      Async do
        @http.request(
          Route.new(
            "#{url}/messages/#{Utils.try(message, :id)}",
            "//webhooks/:webhook_id/:token/messages/:message_id",
            :delete
          )
        ).wait
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
      # @param [Discorb::Client] client The client to associate with the webhook.
      #
      def initialize(url, client: nil)
        @url = url
        @token = ""
        @http = Discorb::HTTP.new(client || Discorb::Client.new)
      end
    end

    #
    # Represents a bot created webhook.
    #
    class IncomingWebhook < Webhook
      # @!attribute [r] url
      #   @return [String] The URL of the webhook.

      #
      # Initializes the incoming webhook.
      # @private
      #
      # @param [Discorb::Client] client The client.
      # @param [String] url The URL of the webhook.
      #
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

      #
      # Initializes the follower webhook.
      # @private
      #
      # @param [Discorb::Client] client The client.
      # @param [Hash] data The data of the follower webhook.
      #
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

        #
        # Initialize a new guild.
        # @private
        #
        # @param [Hash] data The data of the guild.
        #
        def initialize(data)
          @id = Snowflake.new(data[:id])
          @name = data[:name]
          @icon = Asset.new(self, data[:icon])
        end

        def inspect
          "#<#{self.class.name} #{@id}: #{@name}>"
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

        #
        # Initialize a new channel.
        # @private
        #
        # @param [Hash] data The data of the channel.
        #
        def initialize(data)
          @id = Snowflake.new(data[:id])
          @name = data[:name]
        end

        def inspect
          "#<#{self.class.name} #{@id}: #{@name}>"
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

      #
      # Initializes the message.
      # @private
      #
      # @param [Discorb::Webhook] webhook The webhook.
      # @param [Hash] data The data of the message.
      # @param [Discorb::Client] client The client. This will be nil if it's created from {URLWebhook}.
      def initialize(webhook, data, client = nil)
        @client = client
        @webhook = webhook
        @data = data
        _set_data(data)
      end

      #
      # Edits the message.
      # @async
      # @macro edit
      #
      # @param (see Webhook#edit_message)
      #
      # @return [Async::Task<void>] The task.
      #
      def edit(...)
        Async { @webhook.edit_message(self, ...).wait }
      end

      #
      # Deletes the message.
      # @async
      #
      # @return [Async::Task<void>] The task.
      #
      def delete
        Async { @webhook.delete_message(self).wait }
      end

      private

      def _set_data(data)
        @id = Snowflake.new(data[:id])
        @type = Discorb::Message::MESSAGE_TYPE[data[:type]]
        @content = data[:content]
        @channel_id = Snowflake.new(data[:channel_id])
        @author = Author.new(data[:author])
        @attachments = data[:attachments].map { |a| Attachment.new(a) }
        @embeds =
          data[:embeds] ? data[:embeds].map { |e| Embed.from_hash(e) } : []
        @mentions = data[:mentions].map { |m| Mention.new(m) }
        @mention_roles = data[:mention_roles].map { |m| Snowflake.new(m) }
        @mention_everyone = data[:mention_everyone]
        @pinned = data[:pinned]
        @tts = data[:tts]
        @created_at = data[:edited_timestamp] && Time.iso8601(data[:timestamp])
        @updated_at =
          data[:edited_timestamp] && Time.iso8601(data[:edited_timestamp])
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

        #
        # Initializes the author.
        # @private
        #
        # @param [Hash] data The data of the author.
        #
        def initialize(data)
          @data = data
          @bot = data[:bot]
          @id = Snowflake.new(data[:id])
          @username = data[:username]
          @avatar =
            (
              if data[:avatar]
                Asset.new(self, data[:avatar])
              else
                DefaultAvatar.new(data[:discriminator])
              end
            )
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

        def inspect
          "#<#{self.class.name} #{self}>"
        end
      end
    end

    class << self
      #
      # Creates URLWebhook.
      #
      # @param [String] url The URL of the webhook.
      # @param [Discorb::Client] client The client to associate with the webhook.
      #
      # @return [Discorb::Webhook::URLWebhook] The URLWebhook.
      #
      def new(url, client: nil)
        if self == Webhook
          URLWebhook.new(url, client: client)
        else
          super
        end
      end

      #
      # Creates Webhook with discord data.
      # @private
      #
      # @param [Discorb::Client] client The client.
      # @param [Hash] data The data of the webhook.
      #
      # @return [Discorb::Webhook] The Webhook.
      #
      def from_data(client, data)
        case data[:type]
        when 1
          IncomingWebhook
        when 2
          FollowerWebhook
        when 3
          ApplicationWebhook
        end.new(data, client: @client)
      end

      def from_url(url)
        URLWebhook.new(url)
      end
    end
  end
end
