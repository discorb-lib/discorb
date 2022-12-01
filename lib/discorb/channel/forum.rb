# frozen_string_literal: true

module Discorb
  #
  # Represents a forum channel.
  #
  class ForumChannel < GuildChannel
    # @return [String] The guideline of the channel.
    attr_reader :guideline
    alias topic guideline
    # @return [Boolean] Whether the channel is nsfw.
    attr_reader :nsfw
    # @return [Discorb::Snowflake] The id of the last message.
    attr_reader :last_message_id
    # @return [Integer] The rate limit to create thread per user (Slowmode) in the channel.
    attr_reader :rate_limit_per_user
    alias slowmode rate_limit_per_user
    alias thread_slowmode rate_limit_per_user
    # @return [Integer] The rate limit to send message per user (Slowmode) in the channel.
    attr_reader :message_rate_limit_per_user
    alias message_slowmode message_rate_limit_per_user
    # @return [Integer] The default value of duration of auto archive.
    attr_reader :default_auto_archive_duration
    # @return [:latest_activity, :creation_date] The default sort order of the channel.
    attr_reader :default_sort_order
    # @return [Array<Discorb::ForumChannel::Tag>] The tags in the channel.
    attr_reader :tags
    # @return [Boolean] Whether at least one tag is required.
    attr_reader :require_tag
    alias require_tag? require_tag

    @channel_type = 15

    # @!attribute [r] threads
    #   @return [Array<Discorb::ThreadChannel>] The threads in the channel.
    def threads
      guild.threads.select { |thread| thread.parent == self }
    end

    DEFAULT_SORT_ORDER = { 1 => :latest_activity, 2 => :creation_date }.freeze

    #
    # Represents a tag in the forum channel.
    #
    class Tag < DiscordModel
      # @return [Snowflake] The id of the tag.
      attr_reader :id
      # @return [String] The name of the tag.
      attr_reader :name
      # @return [Boolean] Whether the tag is moderated. (aka moderator only)
      attr_reader :moderated
      alias moderated? moderated
      # @return [Discorb::Emoji] The emoji of the tag.
      attr_reader :emoji

      #
      # Initializes a new tag.
      #
      # @param [String] name The name of the tag.
      # @param [Discorb::Emoji] emoji The emoji of the tag.
      # @param [Boolean] moderated Whether the tag is moderated. (aka moderator only)
      #
      # @return [Discorb::ForumChannel::Tag] The new tag.
      #
      def initialize(name, emoji, moderated: false)
        @id = nil
        @name = name
        @emoji = emoji
        @moderated = moderated
      end

      #
      # Returns the tag as a hash.
      #
      # @return [Hash] The tag as a hash.
      #
      def to_hash
        { id: id, name: name, moderated: moderated, emoji: emoji }
      end

      # @private
      def self.from_data(guild, data)
        tag = allocate
        tag.send(:_set_data, guild, data)
        tag
      end

      def inspect
        "#<#{self.class}: #{name} id=#{id}>"
      end

      private

      def _set_data(guild, data)
        @id = Snowflake.new(data[:id])
        @name = data[:name]
        @moderated = data[:moderated]
        @emoji =
          if data[:emoji_id]
            guild.emojis[data[:emoji_id]]
          elsif data[:emoji_name]
            UnicodeEmoji.new(data[:emoji_name])
          end
      end
    end

    #
    # Represents a thread in the forum channel.
    #
    class Post < ThreadChannel
      @channel_type = 11

      # @return [Array<Discorb::ForumChannel::Tag>] The tags of the post.
      attr_reader :tags
      # @return [Boolean] Whether the post is pinned.
      attr_reader :pinned
      alias pinned? pinned

      #
      # Edit the thread.
      # @async
      # @macro edit
      #
      # @param [String] name The name of the thread.
      # @param [Boolean] archived Whether the thread is archived or not.
      # @param [Integer] auto_archive_duration The auto archive duration in seconds.
      # @param [Integer] archive_in Alias of `auto_archive_duration`.
      # @param [Boolean] locked Whether the thread is locked or not.
      # @param [String] reason The reason of editing the thread.
      # @param [Boolean] pinned Whether the thread is pinned or not.
      # @param [Array<Discorb::ForumChannel::Tag>] tags The tags of the thread.
      #
      # @return [Async::Task<self>] The edited thread.
      #
      # @see #archive
      # @see #lock
      # @see #unarchive
      # @see #unlock
      # @see #pin
      # @see #unpin
      # @see #add_tags
      # @see #remove_tags
      #
      def edit(
        name: Discorb::Unset,
        archived: Discorb::Unset,
        auto_archive_duration: Discorb::Unset,
        archive_in: Discorb::Unset,
        locked: Discorb::Unset,
        pinned: Discorb::Unset,
        tags: Discorb::Unset,
        reason: nil
      )
        Async do
          payload = {}
          payload[:name] = name if name != Discorb::Unset
          payload[:archived] = archived if archived != Discorb::Unset
          auto_archive_duration ||= archive_in
          payload[
            :auto_archive_duration
          ] = auto_archive_duration if auto_archive_duration != Discorb::Unset
          payload[:locked] = locked if locked != Discorb::Unset
          payload[:flags] = pinned ? 1 : 0 if pinned != Discorb::Unset
          payload[:applied_tags] = tags.map(&:id) if tags != Discorb::Unset
          @client
            .http
            .request(
              Route.new("/channels/#{@id}", "//channels/:channel_id", :patch),
              payload,
              audit_log_reason: reason
            )
            .wait
          self
        end
      end

      #
      # Pins the thread.
      # @async
      #
      # @param [String] reason The reason of pinning the thread.
      #
      # @return [Async::Task<self>] The pinned thread.
      #
      # @see #unpin
      # @see #pinned?
      #
      def pin(reason: nil)
        edit(pinned: true, reason: reason)
      end

      #
      # Unpins the thread.
      # @async
      #
      # @param [String] reason The reason of unpinning the thread.
      #
      # @return [Async::Task<self>] The unpinned thread.
      #
      # @see #pin
      # @see #pinned?
      #
      def unpin(reason: nil)
        edit(pinned: false, reason: reason)
      end

      #
      # Adds tags to the thread.
      # @async
      #
      # @param [Array<Discorb::ForumChannel::Tag>] tags The tags to add.
      # @param [String] reason The reason of adding tags.
      # @return [Async::Task<self>] The thread with added tags.
      #
      # @see #remove_tags
      # @see #tags
      #
      def add_tags(*tags, reason: nil)
        edit(tags: self.tags + tags, reason: reason)
      end

      #
      # Removes tags from the thread.
      # @async
      #
      # @param [Array<Discorb::ForumChannel::Tag>] tags The tags to remove.
      # @param [String] reason The reason of removing tags.
      # @return [Async::Task<self>] The thread with removed tags.
      #
      # @see #add_tags
      # @see #tags
      #
      def remove_tags(*tags, reason: nil)
        edit(tags: self.tags - tags, reason: reason)
      end

      private

      def _set_data(data)
        super(data)
        @tags = data[:applied_tags].map { |tag| parent.tags[tag] }
        @pinned = data[:flags] == 1
      end
    end

    def initialize(client, data, no_cache: false)
      super
      _set_data(data)
    end

    def inspect
      "#<#{self.class}: #{name} id=#{id}>"
    end

    #
    # Edits the channel.
    # @async
    # @macro edit
    #
    # @param [String] name The name of the channel.
    # @param [Integer] position The position of the channel.
    # @param [Discorb::CategoryChannel, nil] category The parent of channel. Specify `nil` to remove the parent.
    # @param [Discorb::CategoryChannel, nil] parent Alias of `category`.
    # @param [String] topic The topic of the channel.
    # @param [String] guideline Alias of `topic`.
    # @param [Boolean] nsfw Whether the channel is nsfw.
    # @param [Integer] rate_limit_per_user The rate limit per user (Slowmode) in the channel.
    # @param [Integer] slowmode Alias of `rate_limit_per_user`.
    # @param [Integer] thread_rate_limit_per_user The rate limit per user (Slowmode) in threads.
    # @param [Integer] thread_slowmode Alias of `thread_rate_limit_per_user`.
    # @param [Integer] default_auto_archive_duration The default auto archive duration of the channel.
    # @param [Integer] archive_in Alias of `default_auto_archive_duration`.
    # @param [Boolean] require_tag Whether the channel requires tag to create thread.
    # @param [Discorb::Emoji] default_reaction_emoji The default reaction emoji of the channel.
    # @param [:latest_activity, :creation_date] default_sort_order The default sort order of the channel.
    # @param [Array<Discorb::ForumChannel::Tag>] tags The tags of the channel.
    # @param [String] reason The reason of editing the channel.
    #
    # @return [Async::Task<self>] The edited channel.
    #
    # @see #create_tags
    # @see #delete_tags
    #
    def edit(
      name: Discorb::Unset,
      position: Discorb::Unset,
      category: Discorb::Unset,
      parent: Discorb::Unset,
      topic: Discorb::Unset,
      guideline: Discorb::Unset,
      nsfw: Discorb::Unset,
      rate_limit_per_user: Discorb::Unset,
      slowmode: Discorb::Unset,
      thread_rate_limit_per_user: Discorb::Unset,
      thread_slowmode: Discorb::Unset,
      default_auto_archive_duration: Discorb::Unset,
      archive_in: Discorb::Unset,
      require_tag: Discorb::Unset,
      default_reaction_emoji: Discorb::Unset,
      default_sort_order: Discorb::Unset,
      tags: Discorb::Unset,
      reason: nil
    )
      Async do
        payload = {}
        payload[:name] = name unless name == Discorb::Unset
        payload[:position] = position unless position == Discorb::Unset
        payload[:parent_id] = category.id unless category == Discorb::Unset
        payload[:parent_id] = parent.id unless parent == Discorb::Unset
        payload[:topic] = topic unless topic == Discorb::Unset
        payload[:topic] = guideline unless guideline == Discorb::Unset
        payload[:nsfw] = nsfw unless nsfw == Discorb::Unset
        payload[
          :rate_limit_per_user
        ] = rate_limit_per_user unless rate_limit_per_user == Discorb::Unset
        payload[:rate_limit_per_user] = slowmode unless slowmode ==
          Discorb::Unset
        payload[
          :thread_rate_limit_per_user
        ] = thread_rate_limit_per_user unless thread_rate_limit_per_user ==
          Discorb::Unset
        payload[
          :thread_rate_limit_per_user
        ] = thread_slowmode unless thread_slowmode == Discorb::Unset
        payload[
          :default_auto_archive_duration
        ] = default_auto_archive_duration unless default_auto_archive_duration ==
          Discorb::Unset
        payload[
          :default_auto_archive_duration
        ] = archive_in unless archive_in == Discorb::Unset
        payload[:flags] = (require_tag ? 1 << 4 : 0) unless require_tag ==
          Discorb::Unset
        payload[:default_reaction_emoji] = default_reaction_emoji
          .to_hash
          .then do |e|
          { emoji_name: e[:name], emoji_id: e[:id] }
        end unless default_reaction_emoji == Discorb::Unset
        payload[:default_sort_order] = DEFAULT_SORT_ORDER.key(
          default_sort_order
        ) unless default_sort_order == Discorb::Unset
        payload[:available_tags] = tags.map(&:to_hash) unless tags ==
          Discorb::Unset
        ret =
          @client
            .http
            .request(
              Route.new("/channels/#{id}", "//channels/:channel_id", :patch),
              reason: reason
            )
            .wait
        _set_data(ret)
        if tags != Discorb::Unset
          tags
            .reject(&:id)
            .each do |tag|
              tag.instance_variable_set(
                :@id,
                ret[:available_tags].find { |t| t.to_hash == tag.to_hash }[:id]
              )
            end
        end
        self
      end
    end

    alias modify edit

    #
    # Creates tags to the channel.
    # @async
    #
    # @param [Array<Discorb::ForumChannel::Tag>] tags The tags to create.
    # @param [String] reason The reason of creating tags.
    #
    # @return [Async::Task<self>] The edited channel.
    #
    # @see #edit
    #
    def create_tags(*tags, reason: nil)
      edit(tags: self.tags + tags, reason: reason)
    end

    #
    # Deletes tags from the channel.
    # @async
    #
    # @param [Array<Discorb::ForumChannel::Tag>] tags The tags to delete.
    # @param [String] reason The reason of deleting tags.
    #
    # @return [Async::Task<self>] The edited channel.
    #
    # @see #edit
    #
    def delete_tags(*tags, reason: nil)
      edit(tags: self.tags - tags, reason: reason)
    end

    #
    # Create webhook in the channel.
    # @async
    #
    # @param [String] name The name of the webhook.
    # @param [Discorb::Image] avatar The avatar of the webhook.
    #
    # @return [Async::Task<Discorb::Webhook::IncomingWebhook>] The created webhook.
    #
    def create_webhook(name, avatar: nil)
      Async do
        payload = {}
        payload[:name] = name
        payload[:avatar] = avatar.to_s if avatar
        _resp, data =
          @client
            .http
            .request(
              Route.new(
                "/channels/#{@id}/webhooks",
                "//channels/:channel_id/webhooks",
                :post
              ),
              payload
            )
            .wait
        Webhook.from_data(@client, data)
      end
    end

    #
    # Fetch webhooks in the channel.
    # @async
    #
    # @return [Async::Task<Array<Discorb::Webhook>>] The webhooks in the channel.
    #
    def fetch_webhooks
      Async do
        _resp, data =
          @client
            .http
            .request(
              Route.new(
                "/channels/#{@id}/webhooks",
                "//channels/:channel_id/webhooks",
                :get
              )
            )
            .wait
        data.map { |webhook| Webhook.from_data(@client, webhook) }
      end
    end

    #
    # Bulk delete messages in the channel.
    # @async
    #
    # @param [Discorb::Message] messages The messages to delete.
    # @param [Boolean] force Whether to ignore the validation for message (14 days limit).
    #
    # @return [Async::Task<void>] The task.
    #
    def delete_messages(*messages, force: false)
      Async do
        messages = messages.flatten
        unless force
          time = Time.now
          messages.delete_if do |message|
            next false unless message.is_a?(Message)

            time - message.created_at > 60 * 60 * 24 * 14
          end
        end

        message_ids = messages.map { |m| Discorb::Utils.try(m, :id).to_s }

        @client
          .http
          .request(
            Route.new(
              "/channels/#{@id}/messages/bulk-delete",
              "//channels/:channel_id/messages/bulk-delete",
              :post
            ),
            { messages: message_ids }
          )
          .wait
      end
    end

    alias bulk_delete delete_messages
    alias destroy_messages delete_messages

    #
    # Start thread in the channel.
    # @async
    #
    # @param [Title] title The title of the thread.
    # @param [String] content The message content.
    # @param [Discorb::Embed] embed The embed to send.
    # @param [Array<Discorb::Embed>] embeds The embeds to send.
    # @param [Discorb::AllowedMentions] allowed_mentions The allowed mentions.
    # @param [Array<Discorb::Component>, Array<Array<Discorb::Component>>] components The components to send.
    # @param [Discorb::Attachment] attachment The attachment to send.
    # @param [Array<Discorb::Attachment>] attachments The attachments to send.
    # @param [Array<Discorb::ForumChannel::Tag>] tags The tags to attach.
    # @param [:hour, :day, :three_days, :week] auto_archive_duration The duration of auto-archiving.
    # @param [Integer] rate_limit_per_user The rate limit per user.
    # @param [Integer] slowmode Alias of `rate_limit_per_user`.
    #
    # @return [Async::Task<Discorb::PublicThread>] The created thread.
    #
    def post(
      title,
      content = nil,
      embed: nil,
      embeds: nil,
      allowed_mentions: nil,
      components: nil,
      attachment: nil,
      attachments: nil,
      tags: nil,
      auto_archive_duration: nil,
      rate_limit_per_user: nil,
      slowmode: nil,
      reason: nil
    )
      Async do
        message_payload = {}
        message_payload[:content] = content if content
        tmp_embed =
          if embed
            [embed]
          elsif embeds
            embeds
          end
        message_payload[:embeds] = tmp_embed.map(&:to_hash) if tmp_embed
        message_payload[:allowed_mentions] = (
          if allowed_mentions
            allowed_mentions.to_hash(@client.allowed_mentions)
          else
            @client.allowed_mentions.to_hash
          end
        )
        message_payload[:components] = Component.to_payload(
          components
        ) if components
        attachments ||= attachment ? [attachment] : []

        message_payload[:attachments] = attachments.map.with_index do |a, i|
          { id: i, filename: a.filename, description: a.description }
        end

        payload = {}
        payload[:name] = title
        payload[
          :auto_archive_duration
        ] = auto_archive_duration if auto_archive_duration
        payload[:rate_limit_per_user] = rate_limit_per_user ||
          slowmode if rate_limit_per_user || slowmode
        payload[:message] = message_payload
        payload[:applied_tags] = tags.map(&:id) if tags

        _resp, data =
          @client
            .http
            .multipart_request(
              Route.new(
                "/channels/#{channel_id.wait}/threads",
                "//channels/:channel_id/threads",
                :post
              ),
              payload,
              attachments,
              audit_log_reason: reason
            )
            .wait
        Channel.make_channel(@client, data)
      end
    end

    alias start_thread post
    alias create_thread start_thread

    #
    # Fetch archived threads in the channel.
    # @async
    #
    # @return [Async::Task<Array<Discorb::ThreadChannel>>] The archived threads in the channel.
    #
    def fetch_archived_threads
      Async do
        _resp, data =
          @client
            .http
            .request(
              Route.new(
                "/channels/#{@id}/threads/archived/public",
                "//channels/:channel_id/threads/archived/public",
                :get
              )
            )
            .wait
        data.map { |thread| Channel.make_channel(@client, thread) }
      end
    end

    private

    def _set_data(data)
      @topic = data[:topic]
      @nsfw = data[:nsfw]
      @last_message_id = Snowflake.new data[:last_message_id]
      @rate_limit_per_user = data[:rate_limit_per_user]
      @default_auto_archive_duration = data[:default_auto_archive_duration]
      @message_rate_limit_per_user = data[:message_rate_limit_per_user]
      @default_sort_order = DEFAULT_SORT_ORDER[data[:default_sort_order]]
      @tags =
        Dictionary.new(
          data[:available_tags].to_h do |tag|
            Tag.from_data(guild, tag).then { |t| [t.id, t] }
          end
        )
      @require_tag = data[:flags] & (1 << 4) != 0
      super
    end
  end
end
