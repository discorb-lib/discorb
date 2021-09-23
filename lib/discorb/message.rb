# frozen_string_literal: true

module Discorb
  #
  # Represents a allowed mentions in a message.
  #
  class AllowedMentions
    # @return [Boolean] Whether to allow @everyone or @here.
    attr_accessor :everyone
    # @return [Boolean, Array<Discorb::Role>] The roles to allow, or false to disable.
    attr_accessor :roles
    # @return [Boolean, Array<Discorb::User>] The users to allow, or false to disable.
    attr_accessor :users
    # @return [Boolean] Whether to ping the user that sent the message to reply.
    attr_accessor :replied_user

    #
    # Initializes a new instance of the AllowedMentions class.
    #
    # @param [Boolean] everyone Whether to allow @everyone or @here.
    # @param [Boolean, Array<Discorb::Role>] roles The roles to allow, or false to disable.
    # @param [Boolean, Array<Discorb::User>] users The users to allow, or false to disable.
    # @param [Boolean] replied_user Whether to ping the user that sent the message to reply.
    #
    def initialize(everyone: nil, roles: nil, users: nil, replied_user: nil)
      @everyone = everyone
      @roles = roles
      @users = users
      @replied_user = replied_user
    end

    # @!visibility private
    def to_hash(other = nil)
      payload = {
        parse: %w[everyone roles users],
      }
      replied_user = nil_merge(@replied_user, other&.replied_user)
      everyone = nil_merge(@everyone, other&.everyone)
      roles = nil_merge(@roles, other&.roles)
      users = nil_merge(@users, other&.users)
      payload[:replied_user] = replied_user
      payload[:parse].delete("everyone") if everyone == false
      if (roles == false) || roles.is_a?(Array)
        payload[:roles] = roles.map { |u| u.id.to_s } if roles.is_a? Array
        payload[:parse].delete("roles")
      end
      if (users == false) || users.is_a?(Array)
        payload[:users] = users.map { |u| u.id.to_s } if users.is_a? Array
        payload[:parse].delete("users")
      end
      payload
    end

    def nil_merge(*args)
      args.each do |a|
        return a unless a.nil?
      end
      nil
    end
  end

  #
  # Represents a message.
  #
  class Message < DiscordModel
    # @return [Discorb::Snowflake] The ID of the message.
    attr_reader :id
    # @return [Discorb::User, Discorb::Member] The user that sent the message.
    attr_reader :author
    # @return [String] The content of the message.
    attr_reader :content
    alias to_s content
    # @return [Time] The time the message was created.
    attr_reader :created_at
    alias timestamp created_at
    alias sent_at created_at
    # @return [Time] The time the message was edited.
    # @return [nil] If the message was not edited.
    attr_reader :updated_at
    alias edited_at updated_at
    alias edited_timestamp updated_at
    # @return [Array<Discorb::Attachment>] The attachments of the message.
    attr_reader :attachments
    # @return [Array<Discorb::Embed>] The embeds of the message.
    attr_reader :embeds
    # @return [Array<Discorb::Reaction>] The reactions of the message.
    attr_reader :reactions
    # @return [Discorb::Snowflake] The ID of the channel the message was sent in.
    attr_reader :webhook_id
    # @return [Symbol] The type of the message.
    # Currently, this will be one of:
    #
    # * `:default`
    # * `:recipient_add`
    # * `:recipient_remove`
    # * `:call`
    # * `:channel_name_change`
    # * `:channel_icon_change`
    # * `:channel_pinned_message`
    # * `:guild_member_join`
    # * `:user_premium_guild_subscription`
    # * `:user_premium_guild_subscription_tier_1`
    # * `:user_premium_guild_subscription_tier_2`
    # * `:user_premium_guild_subscription_tier_3`
    # * `:channel_follow_add`
    # * `:guild_discovery_disqualified`
    # * `:guild_discovery_requalified`
    # * `:guild_discovery_grace_period_initial_warning`
    # * `:guild_discovery_grace_period_final_warning`
    # * `:thread_created`
    # * `:reply`
    # * `:application_command`
    # * `:thread_starter_message`
    # * `:guild_invite_reminder`
    attr_reader :type
    # @return [Discorb::Message::Activity] The activity of the message.
    attr_reader :activity
    # @return [Discorb::Application] The application of the message.
    attr_reader :application_id
    # @return [Discorb::Message::Reference] The reference of the message.
    attr_reader :message_reference
    # @return [Discorb::Message::Flag] The flag of the message.
    # @see Discorb::Message::Flag
    attr_reader :flag
    # @return [Discorb::Message::Sticker] The sticker of the message.
    attr_reader :stickers
    # @return [Discorb::Message::Interaction] The interaction of the message.
    attr_reader :interaction
    # @return [Discorb::ThreadChannel] The thread channel of the message.
    attr_reader :thread
    # @return [Array<Array<Discorb::Component>>] The components of the message.
    attr_reader :components
    # @return [Boolean] Whether the message is deleted.
    attr_reader :deleted
    alias deleted? deleted
    # @return [Boolean] Whether the message is tts.
    attr_reader :tts
    alias tts? tts
    # @return [Boolean] Whether the message mentions everyone.
    attr_reader :mention_everyone
    alias mention_everyone? mention_everyone
    # @return [Boolean] Whether the message is pinned.
    attr_reader :pinned
    alias pinned? pinned
    @message_type = {
      default: 0,
      recipient_add: 1,
      recipient_remove: 2,
      call: 3,
      channel_name_change: 4,
      channel_icon_change: 5,
      channel_pinned_message: 6,
      guild_member_join: 7,
      user_premium_guild_subscription: 8,
      user_premium_guild_subscription_tier_1: 9,
      user_premium_guild_subscription_tier_2: 10,
      user_premium_guild_subscription_tier_3: 11,
      channel_follow_add: 12,
      guild_discovery_disqualified: 14,
      guild_discovery_requalified: 15,
      guild_discovery_grace_period_initial_warning: 16,
      guild_discovery_grace_period_final_warning: 17,
      thread_created: 18,
      reply: 19,
      application_command: 20,
      thread_starter_message: 21,
      guild_invite_reminder: 22,
    }.freeze

    # @!attribute [r] channel
    #   @macro client_cache
    #   @return [Discorb::Channel] The channel the message was sent in.
    # @!attribute [r] guild
    #   @macro client_cache
    #   @return [Discorb::Guild] The guild the message was sent in.
    #   @return [nil] If the message was not sent in a guild.
    # @!attribute [r] webhook?
    #   @return [Boolean] Whether the message was sent by a webhook.
    # @!attribute [r] edited?
    #   @return [Boolean] Whether the message was edited.
    # @!attribute [r] jump_url
    #   @return [String] The URL to jump to the message.
    # @!attribute [r] embed
    #   @return [Discorb::Embed] The embed of the message.
    #   @return [nil] If the message has no embed.

    # @!visibility private
    def initialize(client, data, no_cache: false)
      @client = client
      @data = {}
      @no_cache = no_cache
      _set_data(data)
      @client.messages[@id] = self unless @no_cache
    end

    def channel
      @dm || @client.channels[@channel_id]
    end

    def guild
      @client.guilds[@guild_id]
    end

    def webhook?
      @webhook_id != nil
    end

    def jump_url
      "https://discord.com/channels/#{@guild_id || "@me"}/#{@channel_id}/#{@id}"
    end

    def edited?
      !@updated_at.nil?
    end

    #
    # Removes the mentions from the message.
    #
    # @param [Boolean] user Whether to clean user mentions.
    # @param [Boolean] channel Whether to clean channel mentions.
    # @param [Boolean] role Whether to clean role mentions.
    # @param [Boolean] emoji Whether to clean emoji.
    # @param [Boolean] everyone Whether to clean `@everyone` and `@here`.
    # @param [Boolean] codeblock Whether to clean codeblocks.
    #
    # @return [String] The cleaned content of the message.
    #
    def clean_content(user: true, channel: true, role: true, emoji: true, everyone: true, codeblock: false)
      ret = @content.dup
      ret.gsub!(/<@!?(\d+)>/) do |match|
        member = guild&.members&.[]($1)
        member ||= @client.users[$1]
        member ? "@#{member.name}" : "@Unknown User"
      end if user
      ret.gsub!(/<#(\d+)>/) do |match|
        channel = @client.channels[$1]
        channel ? "<##{channel.id}>" : "#Unknown Channel"
      end
      ret.gsub!(/<@&(\d+)>/) do |match|
        role = guild&.roles&.[]($1)
        role ? "@#{role.name}" : "@Unknown Role"
      end if role
      ret.gsub!(/<a?:([a-zA-Z0-9_]+):\d+>/) do |match|
        $1
      end if emoji
      ret.gsub!(/@(everyone|here)/, "@\u200b\\1") if everyone
      unless codeblock
        codeblocks = ret.split("```", -1)
        original_codeblocks = @content.scan(/```(.+?)```/m)
        res = []
        max = codeblocks.length
        codeblocks.each_with_index do |codeblock, i|
          if max % 2 == 0 && i == max - 1 or i.even?
            res << codeblock
          else
            res << original_codeblocks[i / 2]
          end
        end
        res.join("```")
      else
        ret
      end
    end

    #
    # Edit the message.
    #
    # @param [String] content The message content.
    # @param [Discorb::Embed] embed The embed to send.
    # @param [Array<Discorb::Embed>] embeds The embeds to send.
    # @param [Discorb::AllowedMentions] allowed_mentions The allowed mentions.
    # @param [Array<Discorb::Component>, Array<Array<Discorb::Component>>] components The components to send.
    # @param [Boolean] supress Whether to supress embeds.
    #
    def edit(message_id, content = nil, embed: nil, embeds: nil, allowed_mentions: nil,
                                        components: nil, supress: nil)
      Async do
        channel.edit_message(@id, message_id, content, embed: embed, embeds: embeds, allowed_mentions: allowed_mentions,
                                                       components: components, supress: supress).wait
      end
    end

    #
    # Delete the message.
    #
    # @param [String] reason The reason for deleting the message.
    #
    def delete!(reason: nil)
      Async do
        channel.delete_message!(@id, reason: reason).wait
      end
    end

    #
    # Convert the message to reference object.
    #
    # @param [Boolean] fail_if_not_exists Whether to raise an error if the message does not exist.
    #
    # @return [Hash] The reference object.
    #
    def to_reference(fail_if_not_exists: true)
      {
        message_id: @id,
        channel_id: @channel_id,
        guild_id: @guild_id,
        fail_if_not_exists: fail_if_not_exists,
      }
    end

    def embed
      @embeds[0]
    end

    # Reply to the message.
    # @macro async
    # @macro http
    # @param (see #post)
    # @return [Async::Task<Discorb::Message>] The message.
    def reply(*args, **kwargs)
      Async do
        channel.post(*args, reference: self, **kwargs).wait
      end
    end

    #
    # Publish the message.
    # @macro async
    # @macro http
    #
    def publish
      Async do
        channel.post("/channels/#{@channel_id}/messages/#{@id}/crosspost", nil).wait
      end
    end

    #
    # Add a reaction to the message.
    # @macro async
    # @macro http
    #
    # @param [Discorb::Emoji] emoji The emoji to react with.
    #
    def add_reaction(emoji)
      Async do
        @client.http.put("/channels/#{@channel_id}/messages/#{@id}/reactions/#{emoji.to_uri}/@me", nil).wait
      end
    end

    alias react_with add_reaction

    #
    # Remove a reaction from the message.
    # @macro async
    # @macro http
    #
    # @param [Discorb::Emoji] emoji The emoji to remove.
    #
    def remove_reaction(emoji)
      Async do
        @client.http.delete("/channels/#{@channel_id}/messages/#{@id}/reactions/#{emoji.to_uri}/@me").wait
      end
    end

    alias delete_reaction remove_reaction

    #
    # Remove other member's reaction from the message.
    # @macro async
    # @macro http
    #
    # @param [Discorb::Emoji] emoji The emoji to remove.
    # @param [Discorb::Member] member The member to remove the reaction from.
    #
    def remove_reaction_of(emoji, member)
      Async do
        @client.http.delete("/channels/#{@channel_id}/messages/#{@id}/reactions/#{emoji.to_uri}/#{member.is_a?(Member) ? member.id : member}").wait
      end
    end

    alias delete_reaction_of remove_reaction_of

    #
    # Fetch reacted users of reaction.
    # @macro async
    # @macro http
    #
    # @param [Discorb::Emoji] emoji The emoji to fetch.
    # @param [Integer, nil] limit The maximum number of users to fetch. `nil` for no limit.
    # @param [Discorb::Snowflake, nil] after The ID of the user to start fetching from.
    #
    # @return [Async::Task<Array<Discorb::User>>] The users.
    #
    def fetch_reacted_users(emoji, limit: nil, after: 0)
      Async do
        if limit.nil? || !limit.positive?
          after = 0
          users = []
          loop do
            _resp, data = @client.http.get("/channels/#{@channel_id}/messages/#{@id}/reactions/#{emoji.to_uri}?limit=100&after=#{after}").wait
            break if data.empty?

            users += data.map { |r| guild&.members&.[](r[:id]) || @client.users[r[:id]] || User.new(@client, r) }

            break if data.length < 100

            after = data[-1][:id]
          end
          next users
        else
          _resp, data = @client.http.get("/channels/#{@channel_id}/messages/#{@id}/reactions/#{emoji.to_uri}?limit=#{limit}&after=#{after}").wait
          next data.map { |r| guild&.members&.[](r[:id]) || @client.users[r[:id]] || User.new(@client, r) }
        end
      end
    end

    #
    # Pin the message.
    # @macro async
    # @macro http
    #
    # @param [String] reason The reason for pinning the message.
    #
    def pin(reason: nil)
      Async do
        channel.pin_message(self, reason: reason).wait
      end
    end

    #
    # Unpin the message.
    # @macro async
    # @macro http
    #
    def unpin
      Async do
        channel.unpin_message(self, reason: reason).wait
      end
    end

    #
    # Start thread from the message.
    #
    # @param (see Discorb::Channel#start_thread)
    #
    # @return [Async::Task<<Type>>] <description>
    #
    def start_thread(*args, **kwargs)
      Async do
        channel.start_thread(*args, message: self, **kwargs).wait
      end
    end

    alias create_thread start_thread

    # Meta

    def inspect
      "#<#{self.class} #{@content.inspect} id=#{@id}>"
    end

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

      # @!visibility private
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

      # @!visibility private
      def initialize(data)
        @name = data[:name]
        @type = self.class.type(data[:type])
      end

      class << self
        # @!visibility private
        attr_reader :type
      end
    end

    class << self
      # @!visibility private
      attr_reader :message_type
    end
  end
end
