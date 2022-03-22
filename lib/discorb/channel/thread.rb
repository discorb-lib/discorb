# frozen_string_literal: true
module Discorb

  #
  # Represents a thread.
  # @abstract
  #
  class ThreadChannel < Channel
    # @return [Discorb::Snowflake] The ID of the channel.
    # @note This ID is same as the starter message's ID
    attr_reader :id
    # @return [String] The name of the thread.
    attr_reader :name
    # @return [Integer] The number of messages in the thread.
    # @note This will stop counting at 50.
    attr_reader :message_count
    # @return [Integer] The number of recipients in the thread.
    # @note This will stop counting at 50.
    attr_reader :member_count
    alias recipient_count member_count
    # @return [Integer] The rate limit per user (slowmode) in the thread.
    attr_reader :rate_limit_per_user
    alias slowmode rate_limit_per_user
    # @return [Array<Discorb::ThreadChannel::Member>] The members of the thread.
    attr_reader :members
    # @return [Time] The time the thread was archived.
    # @return [nil] If the thread is not archived.
    attr_reader :archived_timestamp
    alias archived_at archived_timestamp
    # @return [Integer] Auto archive duration in seconds.
    attr_reader :auto_archive_duration
    alias archive_in auto_archive_duration
    # @return [Boolean] Whether the thread is archived or not.
    attr_reader :archived
    alias archived? archived

    # @!attribute [r] parent
    #   @macro client_cache
    #   @return [Discorb::GuildChannel] The parent channel of the thread.
    # @!attribute [r] me
    #   @return [Discorb::ThreadChannel::Member] The bot's member in the thread.
    #   @return [nil] If the bot is not in the thread.
    # @!attribute [r] joined?
    #   @return [Boolean] Whether the bot is in the thread or not.
    # @!attribute [r] guild
    #   @macro client_cache
    #   @return [Discorb::Guild] The guild of the thread.
    # @!attribute [r] owner
    #   @macro client_cache
    #   @macro members_intent
    #   @return [Discorb::Member] The owner of the thread.

    include Messageable
    @channel_type = nil

    #
    # Initialize a new thread channel.
    # @private
    #
    # @param [Discorb::Client] client The client.
    # @param [Hash] data The data of the thread channel.
    # @param [Boolean] no_cache Whether to disable the cache.
    #
    def initialize(client, data, no_cache: false)
      @members = Dictionary.new
      super
      @client.channels[@id] = self unless no_cache
    end

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
    #
    # @return [Async::Task<self>] The edited thread.
    #
    # @see #archive
    # @see #lock
    # @see #unarchive
    # @see #unlock
    #
    def edit(name: Discorb::Unset, archived: Discorb::Unset, auto_archive_duration: Discorb::Unset, archive_in: Discorb::Unset, locked: Discorb::Unset, reason: nil)
      Async do
        payload = {}
        payload[:name] = name if name != Discorb::Unset
        payload[:archived] = archived if archived != Discorb::Unset
        auto_archive_duration ||= archive_in
        payload[:auto_archive_duration] = auto_archive_duration if auto_archive_duration != Discorb::Unset
        payload[:locked] = locked if locked != Discorb::Unset
        @client.http.request(Route.new("/channels/#{@id}", "//channels/:channel_id", :patch), payload, audit_log_reason: reason).wait
        self
      end
    end

    #
    # Helper method to archive the thread.
    #
    # @param [String] reason The reason of archiving the thread.
    #
    # @return [self] The archived thread.
    #
    def archive(reason: nil)
      edit(archived: true, reason: reason)
    end

    #
    # Helper method to lock the thread.
    #
    # @param [String] reason The reason of locking the thread.
    #
    # @return [self] The locked thread.
    #
    def lock(reason: nil)
      edit(archived: true, locked: true, reason: reason)
    end

    #
    # Helper method to unarchive the thread.
    #
    # @param [String] reason The reason of unarchiving the thread.
    #
    # @return [self] The unarchived thread.
    #
    def unarchive(reason: nil)
      edit(archived: false, reason: reason)
    end

    #
    # Helper method to unlock the thread.
    #
    # @param [String] reason The reason of unlocking the thread.
    #
    # @return [self] The unlocked thread.
    #
    # @note This method won't unarchive the thread. Use {#unarchive} instead.
    #
    def unlock(reason: nil)
      edit(archived: !unarchive, locked: false, reason: reason)
    end

    def parent
      return nil unless @parent_id

      @client.channels[@parent_id]
    end

    alias channel parent

    def me
      @members[@client.user.id]
    end

    def joined?
      !!me
    end

    def guild
      @client.guilds[@guild]
    end

    def owner
      guild.members[@owner_id]
    end

    def inspect
      "#<#{self.class} \"##{@name}\" id=#{@id}>"
    end

    #
    # Add a member to the thread.
    #
    # @param [Discorb::Member, :me] member The member to add. If `:me` is given, the bot will be added.
    #
    # @return [Async::Task<void>] The task.
    #
    def add_member(member = :me)
      Async do
        if member == :me
          @client.http.request(Route.new("/channels/#{@id}/thread-members/@me", "//channels/:channel_id/thread-members/@me", :post)).wait
        else
          @client.http.request(Route.new("/channels/#{@id}/thread-members/#{Utils.try(member, :id)}", "//channels/:channel_id/thread-members/:user_id", :post)).wait
        end
      end
    end

    alias join add_member

    #
    # Remove a member from the thread.
    #
    # @param [Discorb::Member, :me] member The member to remove. If `:me` is given, the bot will be removed.
    #
    # @return [Async::Task<void>] The task.
    #
    def remove_member(member = :me)
      Async do
        if member == :me
          @client.http.request(Route.new("/channels/#{@id}/thread-members/@me", "//channels/:channel_id/thread-members/@me", :delete)).wait
        else
          @client.http.request(Route.new("/channels/#{@id}/thread-members/#{Utils.try(member, :id)}", "//channels/:channel_id/thread-members/:user_id", :delete)).wait
        end
      end
    end

    alias leave remove_member

    #
    # Fetch members in the thread.
    #
    # @return [Array<Discorb::ThreadChannel::Member>] The members in the thread.
    #
    def fetch_members
      Async do
        _resp, data = @client.http.request(Route.new("/channels/#{@id}/thread-members", "//channels/:channel_id/thread-members", :get)).wait
        data.map { |d| @members[d[:id]] = Member.new(@client, d) }
      end
    end

    #
    # Represents a thread in news channel(aka announcement channel).
    #
    class News < ThreadChannel
      @channel_type = 10
    end

    #
    # Represents a public thread in text channel.
    #
    class Public < ThreadChannel
      @channel_type = 11
    end

    #
    # Represents a private thread in text channel.
    #
    class Private < ThreadChannel
      @channel_type = 12
    end

    class << self
      attr_reader :channel_type
    end

    #
    # Represents a member in a thread.
    #
    class Member < DiscordModel
      attr_reader :joined_at

      def initialize(cilent, data)
        @cilent = cilent
        @thread_id = data[:id]
        @user_id = data[:user_id]
        @joined_at = Time.iso8601(data[:join_timestamp])
      end

      def thread
        @client.channels[@thread_id]
      end

      def member
        thread && thread.members[@user_id]
      end

      def id
        @user_id
      end

      def user
        @cilent.users[@user_id]
      end

      def inspect
        "#<#{self.class} id=#{@id.inspect}>"
      end
    end

    private

    def _set_data(data)
      @id = Snowflake.new(data[:id])
      @name = data[:name]
      @guild_id = data[:guild_id]
      @parent_id = data[:parent_id]
      @archived = data[:thread_metadata][:archived]
      @owner_id = data[:owner_id]
      @archived_timestamp = data[:thread_metadata][:archived_timestamp] && Time.iso8601(data[:thread_metadata][:archived_timestamp])
      @auto_archive_duration = data[:thread_metadata][:auto_archive_duration]
      @locked = data[:thread_metadata][:locked]
      @member_count = data[:member_count]
      @message_count = data[:message_count]
      @members[@client.user.id] = ThreadChannel::Member.new(@client, data[:member].merge({ id: data[:id], user_id: @client.user.id })) if data[:member]
      @data.merge!(data)
    end
  end
end
