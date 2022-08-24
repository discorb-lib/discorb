# frozen_string_literal: true

module Discorb
  module Gateway
    #
    # Represents an event.
    # @abstract
    #
    class GatewayEvent
      #
      # Initializes a new instance of the GatewayEvent class.
      # @private
      #
      # @param [Hash] data The data of the event.
      #
      def initialize(data)
        @data = data
      end

      def inspect
        "#<#{self.class}>"
      end
    end

    #
    # Represents a reaction event.
    #
    class ReactionEvent < GatewayEvent
      # @return [Hash] The raw data of the event.
      attr_reader :data
      # @return [Discorb::Snowflake] The ID of the user who reacted.
      attr_reader :user_id
      alias member_id user_id
      # @return [Discorb::Snowflake] The ID of the channel the message was sent in.
      attr_reader :channel_id
      # @return [Discorb::Snowflake] The ID of the message.
      attr_reader :message_id
      # @return [Discorb::Snowflake] The ID of the guild the message was sent in.
      attr_reader :guild_id
      # @macro client_cache
      # @return [Discorb::User, Discorb::Member] The user who reacted.
      attr_reader :user
      alias member user
      # @macro client_cache
      # @return [Discorb::Channel] The channel the message was sent in.
      attr_reader :channel
      # @macro client_cache
      # @return [Discorb::Guild] The guild the message was sent in.
      attr_reader :guild
      # @macro client_cache
      # @return [Discorb::Message] The message the reaction was sent in.
      attr_reader :message
      # @return [Discorb::UnicodeEmoji, Discorb::PartialEmoji] The emoji that was reacted with.
      attr_reader :emoji

      #
      # Initializes a new instance of the ReactionEvent class.
      # @private
      #
      # @param [Discorb::Client] client The client that instantiated the object.
      # @param [Hash] data The data of the event.
      #
      def initialize(client, data)
        @client = client
        @data = data
        if data.key?(:user_id)
          @user_id = Snowflake.new(data[:user_id])
        else
          @member_data = data[:member]
        end
        @channel_id = Snowflake.new(data[:channel_id])
        @message_id = Snowflake.new(data[:message_id])
        @guild_id = Snowflake.new(data[:guild_id])
        @guild = client.guilds[data[:guild_id]]
        @channel = client.channels[data[:channel_id]] unless @guild.nil?

        @user = client.users[data[:user_id]]

        unless @guild.nil?
          @user =
            if data.key?(:member)
              @guild.members[data[:member][:user][:id]] ||
                Member.new(
                  @client,
                  @guild_id,
                  data[:member][:user],
                  data[:member]
                )
            else
              @guild.members[data[:user_id]]
            end || @user
        end

        @message = client.messages[data[:message_id]]
        @emoji =
          (
            if data[:emoji][:id].nil?
              UnicodeEmoji.new(data[:emoji][:name])
            else
              PartialEmoji.new(data[:emoji])
            end
          )
      end

      # Fetch the message.
      # If message is cached, it will be returned.
      # @async
      #
      # @param [Boolean] force Whether to force fetching the message.
      #
      # @return [Async::Task<Discorb::Message>] The message.
      def fetch_message(force: false)
        Async do
          next @message if !force && @message

          @message = @channel.fetch_message(@message_id).wait
        end
      end
    end

    #
    # Represents a `INTEGRATION_DELETE` event.
    #
    class IntegrationDeleteEvent < GatewayEvent
      # @return [Discorb::Snowflake] The ID of the integration.
      attr_reader :id

      # @!attribute [r] guild
      #   @macro client_cache
      #   @return [Discorb::Guild] The guild of the integration.
      # @!attribute [r] user
      #   @macro client_cache
      #   @return [Discorb::User] The user associated with the integration.

      #
      # Initialize a new instance of the IntegrationDeleteEvent class.
      # @private
      #
      #
      # @param [Hash] data The data of the event.
      #
      #
      def initialize(_client, data)
        @id = Snowflake.new(data[:id])
        @guild_id = data[:guild_id]
        @user_id = data[:application_id]
      end

      def guild
        @client.guilds[@guild_id]
      end

      def user
        @client.users[@user_id]
      end
    end

    #
    # Represents a `MESSAGE_REACTION_REMOVE_ALL` event.
    #
    class ReactionRemoveAllEvent < GatewayEvent
      # @return [Discorb::Snowflake] The ID of the channel the message was sent in.
      attr_reader :channel_id
      # @return [Discorb::Snowflake] The ID of the message.
      attr_reader :message_id
      # @return [Discorb::Snowflake] The ID of the guild the message was sent in.
      attr_reader :guild_id
      # @macro client_cache
      # @return [Discorb::Channel] The channel the message was sent in.
      attr_reader :channel
      # @macro client_cache
      # @return [Discorb::Guild] The guild the message was sent in.
      attr_reader :guild
      # @macro client_cache
      # @return [Discorb::Message] The message the reaction was sent in.
      attr_reader :message

      #
      # Initialize a new instance of the ReactionRemoveAllEvent class.
      # @private
      #
      # @param [Discorb::Client] client The client that instantiated the object.
      # @param [Hash] data The data of the event.
      #
      def initialize(client, data)
        @client = client
        @data = data
        @guild_id = Snowflake.new(data[:guild_id])
        @channel_id = Snowflake.new(data[:channel_id])
        @message_id = Snowflake.new(data[:message_id])
        @guild = client.guilds[data[:guild_id]]
        @channel = client.channels[data[:channel_id]]
        @message = client.messages[data[:message_id]]
      end

      # Fetch the message.
      # If message is cached, it will be returned.
      # @async
      #
      # @param [Boolean] force Whether to force fetching the message.
      #
      # @return [Async::Task<Discorb::Message>] The message.
      def fetch_message(force: false)
        Async do
          next @message if !force && @message

          @message = @channel.fetch_message(@message_id).wait
        end
      end
    end

    #
    # Represents a `MESSAGE_REACTION_REMOVE_EMOJI` event.
    #
    class ReactionRemoveEmojiEvent < GatewayEvent
      # @return [Discorb::Snowflake] The ID of the channel the message was sent in.
      attr_reader :channel_id
      # @return [Discorb::Snowflake] The ID of the message.
      attr_reader :message_id
      # @return [Discorb::Snowflake] The ID of the guild the message was sent in.
      attr_reader :guild_id
      # @macro client_cache
      # @return [Discorb::Channel] The channel the message was sent in.
      attr_reader :channel
      # @macro client_cache
      # @return [Discorb::Guild] The guild the message was sent in.
      attr_reader :guild
      # @macro client_cache
      # @return [Discorb::Message] The message the reaction was sent in.
      attr_reader :message
      # @return [Discorb::UnicodeEmoji, Discorb::PartialEmoji] The emoji that was reacted with.
      attr_reader :emoji

      #
      # Initialize a new instance of the ReactionRemoveEmojiEvent class.
      # @private
      #
      # @param [Discorb::Client] client The client that instantiated the object.
      # @param [Hash] data The data of the event.
      #
      def initialize(client, data)
        @client = client
        @data = data
        @guild_id = Snowflake.new(data[:guild_id])
        @channel_id = Snowflake.new(data[:channel_id])
        @message_id = Snowflake.new(data[:message_id])
        @guild = client.guilds[data[:guild_id]]
        @channel = client.channels[data[:channel_id]]
        @message = client.messages[data[:message_id]]
        @emoji =
          (
            if data[:emoji][:id].nil?
              DiscordEmoji.new(data[:emoji][:name])
            else
              PartialEmoji.new(data[:emoji])
            end
          )
      end

      # Fetch the message.
      # If message is cached, it will be returned.
      # @async
      #
      # @param [Boolean] force Whether to force fetching the message.
      #
      # @return [Async::Task<Discorb::Message>] The message.
      def fetch_message(force: false)
        Async do
          next @message if !force && @message

          @message = @channel.fetch_message(@message_id).wait
        end
      end
    end

    #
    # Represents a `GUILD_SCHEDULED_EVENT_USER_ADD` and `GUILD_SCHEDULED_EVENT_USER_REMOVE` event.
    #
    class ScheduledEventUserEvent < GatewayEvent
      # @return [Discorb::User] The user that triggered the event.
      attr_reader :user
      # @return [Discorb::Guild] The guild the event was triggered in.
      attr_reader :guild
      # @return [Discorb::ScheduledEvent] The scheduled event.
      attr_reader :scheduled_event

      #
      # Initialize a new instance of the ScheduledEventUserEvent class.
      # @private
      #
      # @param [Discorb::Client] client The client that instantiated the object.
      # @param [Hash] data The data of the event.
      #
      def initialize(client, data)
        @client = client
        @scheduled_event_id = Snowflake.new(data[:scheduled_event_id])
        @user_id = Snowflake.new(data[:user_id])
        @guild_id = Snowflake.new(data[:guild_id])
        @guild = client.guilds[data[:guild_id]]
        @scheduled_event = @guild.scheduled_events[@scheduled_event_id]
        @user = client.users[data[:user_id]]
      end
    end

    #
    # Represents a `MESSAGE_UPDATE` event.
    #
    class MessageUpdateEvent < GatewayEvent
      # @return [Discorb::Message] The message before update.
      attr_reader :before
      # @return [Discorb::Message] The message after update.
      attr_reader :after
      # @return [Discorb::Snowflake] The ID of the message.
      attr_reader :id
      # @return [Discorb::Snowflake] The ID of the channel the message was sent in.
      attr_reader :channel_id
      # @return [Discorb::Snowflake] The ID of the guild the message was sent in.
      attr_reader :guild_id
      # @return [String] The new content of the message.
      attr_reader :content
      # @return [Time] The time the message was edited.
      attr_reader :timestamp
      # @return [Boolean] Whether the message pings @everyone.
      attr_reader :mention_everyone
      # @macro client_cache
      # @return [Array<Discorb::Role>] The roles mentioned in the message.
      attr_reader :mention_roles
      # @return [Array<Discorb::Attachment>] The attachments in the message.
      attr_reader :attachments
      # @return [Array<Discorb::Embed>] The embeds in the message.
      attr_reader :embeds

      # @!attribute [r] channel
      #   @macro client_cache
      #   @return [Discorb::Channel] The channel the message was sent in.
      # @!attribute [r] guild
      #   @macro client_cache
      #   @return [Discorb::Guild] The guild the message was sent in.

      def initialize(client, data, before, after)
        @client = client
        @data = data
        @before = before
        @after = after
        @id = Snowflake.new(data[:id])
        @channel_id = Snowflake.new(data[:channel_id])
        @guild_id = Snowflake.new(data[:guild_id]) if data.key?(:guild_id)
        @content = data[:content]
        @timestamp = Time.iso8601(data[:edited_timestamp])
        @mention_everyone = data[:mention_everyone]
        @mention_roles =
          data[:mention_roles].map { |r| guild.roles[r] } if data.key?(
          :mention_roles
        )
        @attachments =
          data[:attachments].map { |a| Attachment.from_hash(a) } if data.key?(
          :attachments
        )
        @embeds =
          (
            if data[:embeds]
              data[:embeds].map { |e| Embed.from_hash(e) }
            else
              []
            end
          ) if data.key?(:embeds)
      end

      def channel
        @client.channels[@channel_id]
      end

      def guild
        @client.guilds[@guild_id]
      end

      # Fetch the message.
      # @async
      #
      # @return [Async::Task<Discorb::Message>] The message.
      def fetch_message
        Async { channel.fetch_message(@id).wait }
      end
    end

    #
    # Represents a message but it has only ID.
    #
    class UnknownDeleteBulkMessage < GatewayEvent
      # @return [Discorb::Snowflake] The ID of the message.
      attr_reader :id

      # @!attribute [r] channel
      #   @macro client_cache
      #   @return [Discorb::Channel] The channel the message was sent in.
      # @!attribute [r] guild
      #   @macro client_cache
      #   @return [Discorb::Guild] The guild the message was sent in.

      #
      # Initialize a new instance of the UnknownDeleteBulkMessage class.
      # @private
      #
      # @param [Discorb::Client] client The client that instantiated the object.
      # @param [Hash] data The data of the event.
      #
      def initialize(client, id, data)
        @client = client
        @id = Snowflake.new(id)
        @data = data
        @channel_id = Snowflake.new(data[:channel_id])
        @guild_id = Snowflake.new(data[:guild_id]) if data.key?(:guild_id)
      end

      def channel
        @client.channels[@channel_id]
      end

      def guild
        @client.guilds[@guild_id]
      end
    end

    #
    # Represents a `INVITE_DELETE` event.
    #
    class InviteDeleteEvent < GatewayEvent
      # @return [String] The invite code.
      attr_reader :code

      # @!attribute [r] channel
      #   @macro client_cache
      #   @return [Discorb::Channel] The channel the message was sent in.
      # @!attribute [r] guild
      #   @macro client_cache
      #   @return [Discorb::Guild] The guild the message was sent in.

      #
      # Initialize a new instance of the InviteDeleteEvent class.
      # @private
      #
      # @param [Discorb::Client] client The client that instantiated the object.
      # @param [Hash] data The data of the event.
      #
      def initialize(client, data)
        @client = client
        @data = data
        @channel_id = Snowflake.new(data[:channel])
        @guild_id = Snowflake.new(data[:guild_id])
        @code = data[:code]
      end

      def channel
        @client.channels[@channel_id]
      end

      def guild
        @client.guilds[@guild_id]
      end
    end

    #
    # Represents a `TYPING_START` event.
    #
    class TypingStartEvent < GatewayEvent
      # @return [Discorb::Snowflake] The ID of the channel the user is typing in.
      attr_reader :user_id

      # @!attribute [r] channel
      #   @macro client_cache
      #   @return [Discorb::Channel] The channel the user is typing in.
      # @!attribute [r] guild
      #   @macro client_cache
      #   @return [Discorb::Guild] The guild the user is typing in.
      # @!attribute [r] user
      #   @macro client_cache
      #   @return [Discorb::User, Discorb::Member] The user that is typing.

      #
      # Initialize a new instance of the TypingStartEvent class.
      # @private
      #
      # @param [Discorb::Client] client The client that instantiated the object.
      # @param [Hash] data The data of the event.
      #
      def initialize(client, data)
        @client = client
        @data = data
        @channel_id = Snowflake.new(data[:channel_id])
        @guild_id = Snowflake.new(data[:guild_id]) if data.key?(:guild_id)
        @user_id = Snowflake.new(data[:user_id])
        @timestamp = Time.at(data[:timestamp])
        if guild
          @member =
            guild.members[@user_id] ||
              Member.new(
                @client,
                @guild_id,
                @client.users[@user_id].instance_variable_get(:@data),
                data[:member]
              )
        end
      end

      def user
        @member || guild&.members&.[](@user_id) || @client.users[@user_id]
      end

      alias member user

      def channel
        @client.channels[@channel_id]
      end

      def guild
        @client.guilds[@guild_id]
      end
    end

    #
    # Represents a message pin event.
    #
    class MessagePinEvent < GatewayEvent
      # @return [Discorb::Message] The message that was pinned.
      attr_reader :message
      # @return [:pinned, :unpinned] The type of event.
      attr_reader :type

      # @!attribute [r] pinned?
      #   @return [Boolean] Whether the message was pinned.
      # @!attribute [r] unpinned?
      #   @return [Boolean] Whether the message was unpinned.

      def initialize(client, data, message)
        @client = client
        @data = data
        @message = message
        @type =
          if message.nil?
            :unknown
          elsif @message.pinned?
            :pinned
          else
            :unpinned
          end
      end

      def pinned?
        @type == :pinned
      end

      def unpinned?
        @type == :unpinned
      end
    end

    #
    # Represents a `WEBHOOKS_UPDATE` event.
    #
    class WebhooksUpdateEvent < GatewayEvent
      # @!attribute [r] channel
      #   @macro client_cache
      #   @return [Discorb::Channel] The channel where the webhook was updated.
      # @!attribute [r] guild
      #   @macro client_cache
      #   @return [Discorb::Guild] The guild where the webhook was updated.

      #
      # Initialize a new instance of the WebhooksUpdateEvent class.
      # @private
      #
      # @param [Discorb::Client] client The client that instantiated the object.
      # @param [Hash] data The data of the event.
      #
      def initialize(client, data)
        @client = client
        @data = data
        @guild_id = Snowflake.new(data[:guild_id])
        @channel_id = Snowflake.new(data[:channel_id])
      end

      def guild
        @client.guilds[@guild_id]
      end

      def channel
        @client.channels[@channel_id]
      end
    end

    #
    # Represents a `AUTO_MODERATION_ACTION_EXECUTION` event.
    #
    class AutoModerationActionExecutionEvent < GatewayEvent
      # @return [Discorb::Snowflake] The id of the rule.
      attr_reader :rule_id

      # @return [Symbol] The type of action that was executed.
      attr_reader :rule_trigger_type

      # @return [Discorb::Snowflake] The id of the message that triggered the action.
      # @return [nil] If the message was deleted.
      attr_reader :message_id

      # @return [Discorb::Snowflake] The id of the system message that was sent.
      # @return [nil] If the system message channel was not set.
      attr_reader :alert_system_message_id

      # @return [String] The content of the message that was sent.
      attr_reader :content

      # @return [String] The keyword that triggered the action.
      # @return [nil] If the action was not triggered by a keyword.
      attr_reader :matched_keyword

      # @return [String] The content that triggered the action.
      # @return [nil] If the action was not triggered by a keyword.
      attr_reader :matched_content

      # @return [Discorb::AutoModRule::Action] The action that was executed.
      attr_reader :action

      #
      # Initialize a new instance of the AutoModerationActionExecutionEvent class.
      # @private
      #
      # @param [Discorb::Client] client The client that instantiated the object.
      # @param [Hash] data The data of the event.
      #
      def initialize(client, data)
        @client = client
        @data = data
        @rule_id = Snowflake.new(data[:rule_id])
        @rule_trigger_type =
          Discorb::AutoModRule::TRIGGER_TYPES[data[:rule_trigger_type]]
        @action = Discorb::AutoModRule::Action.new(data[:action])
        @user_id = Snowflake.new(data[:user_id])
        @guild_id = Snowflake.new(data[:guild_id])
        @channel_id = data[:channel_id] && Snowflake.new(data[:channel_id])
        @message_id = data[:message_id] && Snowflake.new(data[:message_id])
        @alert_system_message_id =
          data[:alert_system_message_id] &&
            Snowflake.new(data[:alert_system_message_id])
        @content = data[:content]
        @matched_keyword = data[:matched_keyword]
        @matched_content = data[:matched_content]
      end

      # @!attribute [r] guild
      #   @return [Discorb::Guild] The guild where the rule was executed.
      def guild
        @client.guilds[@guild_id]
      end

      # @!attribute [r] channel
      #   @return [Discorb::Channel] The channel where the rule was executed.
      def channel
        @client.channels[@channel_id]
      end

      # @!attribute [r] member
      #   @return [Discorb::Member] The member that triggered the action.
      def member
        guild.members[@user_id]
      end

      alias user member
    end
  end
end
