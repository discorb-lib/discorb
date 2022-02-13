module Discorb
  class Message
    #
    # Represents message flag.
    # ## Flag fields
    # |Field|Value|
    # |-|-|
    # |`1 << 0`|`:crossposted`|
    # |`1 << 1`|`:crosspost`|
    # |`1 << 2`|`:supress_embeds`|
    # |`1 << 3`|`:source_message_deleted`|
    # |`1 << 4`|`:urgent`|
    # |`1 << 5`|`:has_thread`|
    # |`1 << 6`|`:ephemeral`|
    # |`1 << 7`|`:loading`|
    #
    class Flag < Discorb::Flag
      @bits = {
        crossposted: 0,
        crosspost: 1,
        supress_embeds: 2,
        source_message_deleted: 3,
        urgent: 4,
        has_thread: 5,
        ephemeral: 6,
        loading: 7,
      }.freeze
    end

    #
    # Represents reference of message.
    #
    class Reference
      # @return [Discorb::Snowflake] The guild ID.
      attr_accessor :guild_id
      # @return [Discorb::Snowflake] The channel ID.
      attr_accessor :channel_id
      # @return [Discorb::Snowflake] The message ID.
      attr_accessor :message_id
      # @return [Boolean] Whether fail the request if the message is not found.
      attr_accessor :fail_if_not_exists

      alias fail_if_not_exists? fail_if_not_exists

      #
      # Initialize a new reference.
      #
      # @param [Discorb::Snowflake] guild_id The guild ID.
      # @param [Discorb::Snowflake] channel_id The channel ID.
      # @param [Discorb::Snowflake] message_id The message ID.
      # @param [Boolean] fail_if_not_exists Whether fail the request if the message is not found.
      #
      def initialize(guild_id, channel_id, message_id, fail_if_not_exists: true)
        @guild_id = guild_id
        @channel_id = channel_id
        @message_id = message_id
        @fail_if_not_exists = fail_if_not_exists
      end

      #
      # Convert the reference to a hash.
      #
      # @return [Hash] The hash.
      #
      def to_hash
        {
          message_id: @message_id,
          channel_id: @channel_id,
          guild_id: @guild_id,
          fail_if_not_exists: @fail_if_not_exists,
        }
      end

      alias to_reference to_hash

      #
      # Initialize a new reference from a hash.
      #
      # @param [Hash] data The hash.
      #
      # @return [Discorb::Message::Reference] The reference.
      # @see https://discord.com/developers/docs/resources/channel#message-reference-object
      #
      def self.from_hash(data)
        new(data[:guild_id], data[:channel_id], data[:message_id], fail_if_not_exists: data[:fail_if_not_exists])
      end
    end

    class Sticker
      attr_reader :id, :name, :format

      def initialize(data)
        @id = Snowflake.new(data[:id])
        @name = data[:name]
        @format = Discorb::Sticker.sticker_format[data[:format]]
      end
    end

    private

    def _set_data(data)
      @id = Snowflake.new(data[:id])
      @channel_id = data[:channel_id]

      if data[:guild_id]
        @guild_id = data[:guild_id]
        @dm = nil
      else
        @dm = Discorb::DMChannel.new(@client, data[:channel_id])
        @guild_id = nil
      end

      if data[:member].nil? && data[:webhook_id]
        @webhook_id = Snowflake.new(data[:webhook_id])
        @author = Webhook::Message::Author.new(data[:author])
      elsif data[:guild_id].nil? || data[:guild_id].empty? || data[:member].nil?
        @author = @client.users[data[:author][:id]] || User.new(@client, data[:author])
      else
        @author = guild&.members&.get(data[:author][:id]) || Member.new(@client,
                                                                        @guild_id, data[:author], data[:member])
      end
      @content = data[:content]
      @created_at = Time.iso8601(data[:timestamp])
      @updated_at = data[:edited_timestamp].nil? ? nil : Time.iso8601(data[:edited_timestamp])

      @tts = data[:tts]
      @mention_everyone = data[:mention_everyone]
      @mention_roles = data[:mention_roles].map { |r| guild.roles[r] }
      @attachments = data[:attachments].map { |a| Attachment.new(a) }
      @embeds = data[:embeds] ? data[:embeds].map { |e| Embed.new(data: e) } : []
      @reactions = data[:reactions] ? data[:reactions].map { |r| Reaction.new(self, r) } : []
      @pinned = data[:pinned]
      @type = self.class.message_type[data[:type]]
      @activity = data[:activity] && Activity.new(data[:activity])
      @application_id = data[:application_id]
      @message_reference = data[:message_reference] && Reference.from_hash(data[:message_reference])
      @flag = Flag.new(0b111 - data[:flags])
      @sticker_items = data[:sticker_items] ? data[:sticker_items].map { |s| Message::Sticker.new(s) } : []
      # @referenced_message = data[:referenced_message] && Message.new(@client, data[:referenced_message])
      @interaction = data[:interaction] && Message::Interaction.new(@client, data[:interaction])
      @thread = data[:thread] && Channel.make_channel(@client, data[:thread])
      @components = data[:components].map { |c| c[:components].map { |co| Component.from_hash(co) } }
      @data.update(data)
      @deleted = false
    end

    #
    # Represents a interaction of message.
    #
    class Interaction < DiscordModel
      # @return [Discorb::Snowflake] The user ID.
      attr_reader :id
      # @return [String] The name of command.
      # @return [nil] If the message is not a command.
      attr_reader :name
      # @return [Class] The type of interaction.
      attr_reader :type
      # @return [Discorb::User] The user.
      attr_reader :user

      # @private
      def initialize(client, data)
        @id = Snowflake.new(data[:id])
        @name = data[:name]
        @type = Discorb::Interaction.descendants.find { |c| c.interaction_type == data[:type] }
        @user = client.users[data[:user][:id]] || User.new(client, data[:user])
      end
    end

    #
    # Represents a activity of message.
    #
    class Activity < DiscordModel
      # @return [String] The name of activity.
      attr_reader :name
      # @return [Symbol] The type of activity.
      attr_reader :type

      @type = {
        1 => :join,
        2 => :spectate,
        3 => :listen,
        5 => :join_request,
      }

      # @private
      def initialize(data)
        @name = data[:name]
        @type = self.class.type(data[:type])
      end

      class << self
        # @private
        attr_reader :type
      end
    end
  end
end
