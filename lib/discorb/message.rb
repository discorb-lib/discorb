# frozen_string_literal: true

module Discorb
  #
  # Represents a message.
  #
  class Message < DiscordModel
    # @return [Discorb::Snowflake] The ID of the message.
    attr_reader :id
    # @return [Discorb::User, Discorb::Member, Webhook::Message::Author] The user that sent the message.
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
    # * `:chat_input_command`
    # * `:thread_starter_message`
    # * `:guild_invite_reminder`
    # * `:context_menu_command`
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
    # @private
    # @return [{Integer => Symbol}] The mapping of message type.
    MESSAGE_TYPE = {
      0 => :default,
      1 => :recipient_add,
      2 => :recipient_remove,
      3 => :call,
      4 => :channel_name_change,
      5 => :channel_icon_change,
      6 => :channel_pinned_message,
      7 => :guild_member_join,
      8 => :user_premium_guild_subscription,
      9 => :user_premium_guild_subscription_tier_1,
      10 => :user_premium_guild_subscription_tier_2,
      11 => :user_premium_guild_subscription_tier_3,
      12 => :channel_follow_add,
      14 => :guild_discovery_disqualified,
      15 => :guild_discovery_requalified,
      16 => :guild_discovery_grace_period_initial_warning,
      17 => :guild_discovery_grace_period_final_warning,
      18 => :thread_created,
      19 => :reply,
      20 => :chat_input_command,
      21 => :thread_starter_message,
      22 => :guild_invite_reminder,
      23 => :context_menu_command,
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
    # @!attribute [r] embed?
    #   @return [Boolean] Whether the message has an embed.
    # @!attribute [r] reply?
    #   @return [Boolean] Whether the message is a reply.
    # @!attribute [r] dm?
    #   @return [Boolean] Whether the message was sent in a DM.
    # @!attribute [r] guild?
    #   @return [Boolean] Whether the message was sent in a guild.

    def embed?
      @embeds.any?
    end

    def reply?
      !@message_reference.nil?
    end

    def dm?
      @guild_id.nil?
    end

    def guild?
      !@guild_id.nil?
    end

    #
    # Initialize a new message.
    # @private
    #
    # @param [Discorb::Client] client The client.
    # @param [Hash] data The data of the welcome screen.
    # @param [Boolean] no_cache Whether to disable caching.
    #
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
      if user
        ret.gsub!(/<@!?(\d+)>/) do |_match|
          member = guild&.members&.[]($1)
          member ||= @client.users[$1]
          member ? "@#{member.name}" : "@Unknown User"
        end
      end
      ret.gsub!(/<#(\d+)>/) do |_match|
        channel = @client.channels[$1]
        channel ? "<##{channel.id}>" : "#Unknown Channel"
      end
      if role
        ret.gsub!(/<@&(\d+)>/) do |_match|
          r = guild&.roles&.[]($1)
          r ? "@#{r.name}" : "@Unknown Role"
        end
      end
      if emoji
        ret.gsub!(/<a?:([a-zA-Z0-9_]+):\d+>/) do |_match|
          $1
        end
      end
      ret.gsub!(/@(everyone|here)/, "@\u200b\\1") if everyone
      if codeblock
        ret
      else
        codeblocks = ret.split("```", -1)
        original_codeblocks = @content.scan(/```(.+?)```/m)
        res = []
        max = codeblocks.length
        codeblocks.each_with_index do |single_codeblock, i|
          res << if max.even? && i == max - 1 || i.even?
            single_codeblock
          else
            original_codeblocks[i / 2]
          end
        end
        res.join("```")
      end
    end

    #
    # Edit the message.
    # @async
    #
    # @param [String] content The message content.
    # @param [Discorb::Embed] embed The embed to send.
    # @param [Array<Discorb::Embed>] embeds The embeds to send.
    # @param [Discorb::AllowedMentions] allowed_mentions The allowed mentions.
    # @param [Array<Discorb::Attachment>] attachments The new attachments.
    # @param [Array<Discorb::Component>, Array<Array<Discorb::Component>>] components The components to send.
    # @param [Boolean] supress Whether to supress embeds.
    #
    # @return [Async::Task<void>] The task.
    #
    def edit(
      content = Discorb::Unset,
      embed: Discorb::Unset,
      embeds: Discorb::Unset,
      allowed_mentions: Discorb::Unset,
      attachments: Discorb::Unset,
      components: Discorb::Unset,
      supress: Discorb::Unset
    )
      Async do
        channel.edit_message(@id, content, embed: embed, embeds: embeds, allowed_mentions: allowed_mentions,
                                           attachments: attachments, components: components, supress: supress).wait
      end
    end

    #
    # Delete the message.
    # @async
    #
    # @param [String] reason The reason for deleting the message.
    #
    # @return [Async::Task<void>] The task.
    #
    def delete(reason: nil)
      Async do
        channel.delete_message(@id, reason: reason).wait
      end
    end

    #
    # Convert the message to reference object.
    #
    # @param [Boolean] fail_if_not_exists Whether to raise an error if the message does not exist.
    #
    # @return [Discorb::Message::Reference] The reference object.
    #
    def to_reference(fail_if_not_exists: true)
      Reference.from_hash(
        {
          message_id: @id,
          channel_id: @channel_id,
          guild_id: @guild_id,
          fail_if_not_exists: fail_if_not_exists,
        }
      )
    end

    def embed
      @embeds[0]
    end

    # Reply to the message.
    # @async
    # @param (see #post)
    # @return [Async::Task<Discorb::Message>] The message.
    def reply(*args, **kwargs)
      Async do
        channel.post(*args, reference: self, **kwargs).wait
      end
    end

    #
    # Publish the message.
    # @async
    #
    # @return [Async::Task<void>] The task.
    #
    def publish
      Async do
        channel.post("/channels/#{@channel_id}/messages/#{@id}/crosspost", nil).wait
      end
    end

    #
    # Add a reaction to the message.
    # @async
    #
    # @param [Discorb::Emoji] emoji The emoji to react with.
    #
    # @return [Async::Task<void>] The task.
    #
    def add_reaction(emoji)
      Async do
        @client.http.request(
          Route.new("/channels/#{@channel_id}/messages/#{@id}/reactions/#{emoji.to_uri}/@me",
                    "//channels/:channel_id/messages/:message_id/reactions/:emoji/@me", :put), nil
        ).wait
      end
    end

    alias react_with add_reaction

    #
    # Remove a reaction from the message.
    # @async
    #
    # @param [Discorb::Emoji] emoji The emoji to remove.
    #
    # @return [Async::Task<void>] The task.
    #
    def remove_reaction(emoji)
      Async do
        @client.http.request(
          Route.new("/channels/#{@channel_id}/messages/#{@id}/reactions/#{emoji.to_uri}/@me",
                    "//channels/:channel_id/messages/:message_id/reactions/:emoji/@me",
                    :delete)
        ).wait
      end
    end

    alias delete_reaction remove_reaction

    #
    # Remove other member's reaction from the message.
    # @async
    #
    # @param [Discorb::Emoji] emoji The emoji to remove.
    # @param [Discorb::Member] member The member to remove the reaction from.
    #
    # @return [Async::Task<void>] The task.
    #
    def remove_reaction_of(emoji, member)
      Async do
        @client.http.request(
          Route.new(
            "/channels/#{@channel_id}/messages/#{@id}/reactions/#{emoji.to_uri}/#{if member.is_a?(Member)
              member.id
            else
              member
            end}",
            "//channels/:channel_id/messages/:message_id/reactions/:emoji/:user_id",
            :delete
          )
        ).wait
      end
    end

    alias delete_reaction_of remove_reaction_of

    #
    # Fetch reacted users of reaction.
    # @async
    #
    # @param [Discorb::Emoji, Discorb::PartialEmoji] emoji The emoji to fetch.
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
            _resp, data = @client.http.request(
              Route.new(
                "/channels/#{@channel_id}/messages/#{@id}/reactions/#{emoji.to_uri}?limit=100&after=#{after}",
                "//channels/:channel_id/messages/:message_id/reactions/:emoji",
                :get
              )
            ).wait
            break if data.empty?

            users += data.map { |r| guild&.members&.[](r[:id]) || @client.users[r[:id]] || User.new(@client, r) }

            break if data.length < 100

            after = data[-1][:id]
          end
          next users
        else
          _resp, data = @client.http.request(
            Route.new(
              "/channels/#{@channel_id}/messages/#{@id}/reactions/#{emoji.to_uri}?limit=#{limit}&after=#{after}",
              "//channels/:channel_id/messages/:message_id/reactions/:emoji",
              :get
            )
          ).wait
          next data.map { |r| guild&.members&.[](r[:id]) || @client.users[r[:id]] || User.new(@client, r) }
        end
      end
    end

    #
    # Pin the message.
    # @async
    #
    # @param [String] reason The reason for pinning the message.
    #
    # @return [Async::Task<void>] The task.
    #
    def pin(reason: nil)
      Async do
        channel.pin_message(self, reason: reason).wait
      end
    end

    #
    # Unpin the message.
    # @async
    #
    # @param [String] reason The reason for unpinning the message.
    #
    # @return [Async::Task<void>] The task.
    #
    def unpin(reason: nil)
      Async do
        channel.unpin_message(self, reason: reason).wait
      end
    end

    #
    # Start thread from the message.
    # @async
    #
    # @param (see Discorb::Channel#start_thread)
    #
    # @return [Async::Task<Discorb::ThreadChannel>] <description>
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
      @attachments = data[:attachments].map { |a| Attachment.from_hash(a) }
      @embeds = data[:embeds] ? data[:embeds].map { |e| Embed.from_hash(e) } : []
      @reactions = data[:reactions] ? data[:reactions].map { |r| Reaction.new(self, r) } : []
      @pinned = data[:pinned]
      @type = MESSAGE_TYPE[data[:type]]
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
  end
end
