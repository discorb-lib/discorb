# frozen_string_literal: true

require "async"

module Discorb
  #
  # Represents a channel of Discord.
  # @abstract
  #
  # @!attribute [r] type
  #   @return [Integer] The type of the channel as integer.
  #
  class Channel < DiscordModel
    # @return [Discorb::Snowflake] The ID of the channel.
    attr_reader :id
    # @return [String] The name of the channel.
    attr_reader :name

    @channel_type = nil
    @subclasses = []

    # @!visibility private
    def initialize(client, data, no_cache: false)
      @client = client
      @data = {}
      @no_cache = no_cache
      _set_data(data)
    end

    #
    # Checks if the channel is other channel.
    #
    # @param [Discorb::Channel] other The channel to check.
    #
    # @return [Boolean] True if the channel is other channel.
    #
    def ==(other)
      return false unless other.respond_to?(:id)

      @id == other.id
    end

    def inspect
      "#<#{self.class} \"##{@name}\" id=#{@id}>"
    end

    # @!visibility private
    def self.descendants
      ObjectSpace.each_object(Class).select { |klass| klass < self }
    end

    # @!visibility private
    def self.make_channel(client, data, no_cache: false)
      descendants.each do |klass|
        return klass.new(client, data, no_cache: no_cache) if !klass.channel_type.nil? && klass.channel_type == data[:type]
      end
      client.log.warn("Unknown channel type #{data[:type]}, initialized GuildChannel")
      GuildChannel.new(client, data)
    end

    class << self
      # @!visibility private
      attr_reader :channel_type
    end

    def type
      self.class.channel_type
    end

    # @!visibility private
    def base_url
      Async do
        "/channels/#{@id}"
      end
    end

    private

    def _set_data(data)
      @id = Snowflake.new(data[:id])
      @name = data[:name]
      @client.channels[@id] = self if !@no_cache && !(data[:no_cache])
      @data.update(data)
    end
  end

  #
  # Represents a channel in guild.
  # @abstract
  # @!attribute [r] mention
  #   @return [String] The mention of the channel.
  #
  # @!attribute [r] parent
  #   @macro client_cache
  #   @return [Discorb::CategoryChannel] The parent of channel.
  #   @return [nil] If the channel is not a child of category.
  #
  # @!attribute [r] guild
  #   @return [Discorb::Guild] The guild of channel.
  #   @macro client_cache
  #
  class GuildChannel < Channel
    # @return [Integer] The position of the channel as integer.
    attr_reader :position
    # @return [Hash{Discorb::Role, Discorb::Member => PermissionOverwrite}] The permission overwrites of the channel.
    attr_reader :permission_overwrites

    include Comparable
    @channel_type = nil

    #
    # Compares position of two channels.
    #
    # @param [Discorb::GuildChannel] other The channel to compare.
    #
    # @return [-1, 1] -1 if the channel is at lower than the other, 1 if the channel is at highter than the other.
    #
    def <=>(other)
      return 0 unless other.respond_to?(:position)

      @position <=> other.position
    end

    #
    # Checks if the channel is same as another.
    #
    # @param [Discorb::GuildChannel] other The channel to check.
    #
    # @return [Boolean] `true` if the channel is same as another.
    #
    def ==(other)
      return false unless other.respond_to?(:id)

      @id == other.id
    end

    #
    # Stringifies the channel.
    #
    # @return [String] The name of the channel with `#`.
    #
    def to_s
      "##{@name}"
    end

    def mention
      "<##{@id}>"
    end

    def parent
      return nil unless @parent_id

      @client.channels[@parent_id]
    end

    alias category parent

    def guild
      @client.guilds[@guild_id]
    end

    def inspect
      "#<#{self.class} \"##{@name}\" id=#{@id}>"
    end

    #
    # Deletes the channel.
    # @macro async
    # @macro http
    #
    # @param [String] reason The reason of deleting the channel.
    #
    # @return [self] The deleted channel.
    #
    def delete!(reason: nil)
      Async do
        @client.internet.delete(base_url.wait.to_s, audit_log_reason: reason).wait
        @deleted = true
        self
      end
    end

    alias close! delete!
    alias destroy! delete!

    #
    # Moves the channel to another position.
    # @macro async
    # @macro http
    #
    # @param [Integer] position The position to move the channel.
    # @param [Boolean] lock_permissions Whether to lock the permissions of the channel.
    # @param [Discorb::CategoryChannel] parent The parent of channel.
    # @param [String] reason The reason of moving the channel.
    #
    # @return [self] The moved channel.
    #
    def move(position, lock_permissions: false, parent: :unset, reason: nil)
      Async do
        payload = {
          position: position,
        }
        payload[:lock_permissions] = lock_permissions
        payload[:parent_id] = parent&.id if parent != :unset
        @client.internet.patch("/guilds/#{@guild_id}/channels", payload, audit_log_reason: reason).wait
      end
    end

    private

    def _set_data(data)
      @guild_id = data[:guild_id]
      @position = data[:position]
      @permission_overwrites = if data[:permission_overwrites]
          data[:permission_overwrites].map do |ow|
            [(ow[:type] == 1 ? guild.roles : guild.members)[ow[:id]], PermissionOverwrite.new(ow[:allow], ow[:deny])]
          end.to_h
        else
          {}
        end
      @parent_id = data[:parent_id]

      super
    end
  end

  #
  # Represents a text channel.
  #
  class TextChannel < GuildChannel
    # @return [String] The topic of the channel.
    attr_reader :topic
    # @return [Boolean] Whether the channel is nsfw.
    attr_reader :nsfw
    # @return [Discorb::Snowflake] The id of the last message.
    attr_reader :last_message_id
    # @return [Integer] The rate limit per user (Slowmode) in the channel.
    attr_reader :rate_limit_per_user
    alias slowmode rate_limit_per_user
    # @return [Time] The time when the last pinned message was pinned.
    attr_reader :last_pin_timestamp
    alias last_pinned_at last_pin_timestamp
    # @return [Array<Discorb::ThreadChannel>] The threads in the channel.
    attr_reader :threads

    include Messageable

    @channel_type = 0

    # @!visibility private
    def initialize(client, data, no_cache: false)
      super
      @threads = Dictionary.new
    end

    #
    # Edits the channel.
    # @macro async
    # @macro http
    # @macro edit
    #
    # @param [String] name The name of the channel.
    # @param [Integer] position The position of the channel.
    # @param [Discorb::CategoryChannel, nil] category The parent of channel. Specify `nil` to remove the parent.
    # @param [Discorb::CategoryChannel, nil] parent Alias of `category`.
    # @param [String] topic The topic of the channel.
    # @param [Boolean] nsfw Whether the channel is nsfw.
    # @param [Boolean] announce Whether the channel is announce channel.
    # @param [Integer] rate_limit_per_user The rate limit per user (Slowmode) in the channel.
    # @param [Integer] slowmode Alias of `rate_limit_per_user`.
    # @param [Integer] default_auto_archive_duration The default auto archive duration of the channel.
    # @param [Integer] archive_in Alias of `default_auto_archive_duration`.
    # @param [String] reason The reason of editing the channel.
    #
    # @return [self] The edited channel.
    #
    def edit(name: :unset, position: :unset, category: :unset, parent: :unset,
             topic: :unset, nsfw: :unset, announce: :unset,
             rate_limit_per_user: :unset, slowmode: :unset, default_auto_archive_duration: :unset,
             archive_in: :unset, reason: nil)
      Async do
        payload = {}
        payload[:name] = name if name != :unset
        payload[:announce] = announce ? 5 : 0 if announce != :unset
        payload[:position] = position if position != :unset
        payload[:topic] = topic || "" if topic != :unset
        payload[:nsfw] = nsfw if nsfw != :unset

        slowmode = rate_limit_per_user if slowmode == :unset
        payload[:rate_limit_per_user] = slowmode || 0 if slowmode != :unset
        parent = category if parent == :unset
        payload[:parent_id] = parent&.id if parent != :unset

        default_auto_archive_duration ||= archive_in
        payload[:default_auto_archive_duration] = default_auto_archive_duration if default_auto_archive_duration != :unset

        @client.internet.patch("/channels/#{@id}", payload, audit_log_reason: reason).wait
        self
      end
    end

    alias modify edit

    #
    # Create webhook in the channel.
    # @macro async
    # @macro http
    #
    # @param [String] name The name of the webhook.
    # @param [Discorb::Image] avatar The avatar of the webhook.
    #
    # @return [Discorb::Webhook::IncomingWebhook] The created webhook.
    #
    def create_webhook(name, avatar: nil)
      Async do
        payload = {}
        payload[:name] = name
        payload[:avatar] = avatar.to_s if avatar
        _resp, data = @client.internet.post("/channels/#{@id}/webhooks", payload).wait
        Webhook.new([@client, data])
      end
    end

    #
    # Fetch webhooks in the channel.
    # @macro async
    # @macro http
    #
    # @return [Array<Discorb::Webhook>] The webhooks in the channel.
    #
    def fetch_webhooks
      Async do
        _resp, data = @client.internet.get("/channels/#{@id}/webhooks").wait
        data.map { |webhook| Webhook.new([@client, webhook]) }
      end
    end

    #
    # Bulk delete messages in the channel.
    # @macro async
    # @macro http
    #
    # @param [Discorb::Message] messages The messages to delete.
    # @param [Boolean] force Whether to ignore the validation for message (14 days limit).
    #
    def delete_messages!(*messages, force: false)
      Async do
        messages = messages.first if messages.length == 1 && messages.first.is_a?(Array)
        unless force
          time = Time.now
          messages.delete_if do |message|
            next false unless message.is_a?(Message)

            time - message.created_at > 60 * 60 * 24 * 14
          end
        end

        message_ids = messages.map { |m| Discorb::Utils.try(m, :id).to_s }

        @client.internet.post("/channels/#{@id}/messages/bulk-delete", { messages: message_ids }).wait
      end
    end

    alias bulk_delete! delete_messages!
    alias destroy_messages! delete_messages!

    #
    # Set the channel's permission overwrite.
    # @macro async
    # @macro http
    #
    # @param [Discorb::Role, Discorb::Member] target The target of the overwrite.
    # @param [String] reason The reason of setting the overwrite.
    # @param [Symbol => Boolean] perms The permission overwrites to replace.
    #
    def set_permissions(target, reason: nil, **perms)
      Async do
        allow_value = @permission_overwrites[target]&.allow_value.to_i
        deny_value = @permission_overwrites[target]&.deny_value.to_i
        perms.each do |perm, value|
          allow_value[Discorb::Permission.bits[perm]] = 1 if value == true
          deny_value[Discorb::Permission.bits[perm]] = 1 if value == false
        end
        payload = {
          allow: allow_value,
          deny: deny_value,
          type: target.is_a?(Member) ? 1 : 0,
        }
        @client.internet.put("/channels/#{@id}/permissions/#{target.id}", payload, audit_log_reason: reason).wait
      end
    end

    alias modify_permissions set_permissions
    alias modify_permisssion set_permissions
    alias edit_permissions set_permissions
    alias edit_permission set_permissions

    #
    # Delete the channel's permission overwrite.
    # @macro async
    # @macro http
    #
    # @param [Discorb::Role, Discorb::Member] target The target of the overwrite.
    # @param [String] reason The reason of deleting the overwrite.
    #
    def delete_permissions(target, reason: nil)
      Async do
        @client.internet.delete("/channels/#{@id}/permissions/#{target.id}", audit_log_reason: reason).wait
      end
    end

    alias delete_permission delete_permissions
    alias destroy_permissions delete_permissions
    alias destroy_permission delete_permissions

    #
    # Fetch the channel's invites.
    # @macro async
    # @macro http
    #
    # @return [Array<Discorb::Invite>] The invites in the channel.
    #
    def fetch_invites
      Async do
        _resp, data = @client.internet.get("/channels/#{@id}/invites").wait
        data.map { |invite| Invite.new(@client, invite) }
      end
    end

    #
    # Create an invite in the channel.
    # @macro async
    # @macro http
    #
    # @param [Integer] max_age The max age of the invite.
    # @param [Integer] max_uses The max uses of the invite.
    # @param [Boolean] temporary Whether the invite is temporary.
    # @param [Boolean] unique Whether the invite is unique.
    #   @note if it's `false` it may return existing invite.
    # @param [String] reason The reason of creating the invite.
    #
    # @return [Invite] The created invite.
    #
    def create_invite(max_age: nil, max_uses: nil, temporary: false, unique: false, reason: nil)
      Async do
        _resp, data = @client.internet.post("/channels/#{@id}/invites", {
          max_age: max_age,
          max_uses: max_uses,
          temporary: temporary,
          unique: unique,
        }, audit_log_reason: reason).wait
        Invite.new(@client, data)
      end
    end

    #
    # Follow the existing announcement channel.
    # @macro async
    # @macro http
    #
    # @param [Discorb::NewsChannel] target The channel to follow.
    # @param [String] reason The reason of following the channel.
    #
    def follow_from(target, reason: nil)
      Async do
        @client.internet.post("/channels/#{target.id}/followers", { webhook_channel_id: @id }, audit_log_reason: reason).wait
      end
    end

    #
    # Follow the existing announcement channel from self.
    # @macro async
    # @macro http
    #
    # @param [Discorb::TextChannel] target The channel to follow to.
    # @param [String] reason The reason of following the channel.
    #
    def follow_to(target, reason: nil)
      Async do
        @client.internet.post("/channels/#{@id}/followers", { webhook_channel_id: target.id }, audit_log_reason: reason).wait
      end
    end

    #
    # Trigger the typing indicator in the channel.
    # @macro async
    # @macro http
    #
    # If block is given, trigger typing indicator during executing block.
    # @example
    #   channel.typing do
    #     channel.post("Waiting for 60 seconds...")
    #     sleep 60
    #     channel.post("Done!")
    #   end
    #
    def typing
      Async do |task|
        if block_given?
          begin
            post_task = task.async do
              @client.internet.post("/channels/#{@id}/typing", {})
              sleep(5)
            end
            yield
          ensure
            post_task.stop
          end
        else
          @client.internet.post("/channels/#{@id}/typing", {})
        end
      end
    end

    #
    # Fetch the pinned messages in the channel.
    # @macro async
    # @macro http
    #
    # @return [Array<Discorb::Message>] The pinned messages in the channel.
    #
    def fetch_pins
      Async do
        _resp, data = @client.internet.get("/channels/#{@id}/pins").wait
        data.map { |pin| Message.new(@client, pin) }
      end
    end

    #
    # Pin a message in the channel.
    # @macro async
    # @macro http
    #
    # @param [Discorb::Message] message The message to pin.
    # @param [String] reason The reason of pinning the message.
    #
    def pin_message(message, reason: nil)
      Async do
        @client.internet.put("/channels/#{@id}/pins/#{message.id}", {}, audit_log_reason: reason).wait
      end
    end

    #
    # Unpin a message in the channel.
    # @macro async
    # @macro http
    #
    # @param [Discorb::Message] message The message to unpin.
    # @param [String] reason The reason of unpinning the message.
    #
    def unpin_message(message, reason: nil)
      Async do
        @client.internet.delete("/channels/#{@id}/pins/#{message.id}", {}, audit_log_reason: reason).wait
      end
    end

    #
    # Start thread in the channel.
    # @macro async
    # @macro http
    #
    # @param [String] name The name of the thread.
    # @param [Discorb::Message] message The message to start the thread.
    # @param [Integer] auto_archive_duration The duration of auto-archiving.
    # @param [Boolean] public Whether the thread is public.
    # @param [String] reason The reason of starting the thread.
    #
    # @return [Discorb::ThreadChannel] The started thread.
    #
    def start_thread(name, message: nil, auto_archive_duration: 1440, public: true, reason: nil)
      Async do
        _resp, data = if message.nil?
            @client.internet.post("/channels/#{@id}/threads", {
              name: name, auto_archive_duration: auto_archive_duration, type: public ? 11 : 10,
            },
                                  audit_log_reason: reason).wait
          else
            @client.internet.post("/channels/#{@id}/messages/#{Utils.try(message, :id)}/threads", {
              name: name, auto_archive_duration: auto_archive_duration,
            }, audit_log_reason: reason).wait
          end
        Channel.make_channel(@client, data)
      end
    end

    alias create_thread start_thread

    #
    # Fetch archived threads in the channel.
    # @macro async
    # @macro http
    #
    # @return [Array<Discorb::ThreadChannel>] The archived threads in the channel.
    #
    def fetch_archived_public_threads
      Async do
        _resp, data = @client.internet.get("/channels/#{@id}/threads/archived/public").wait
        data.map { |thread| Channel.make_channel(@client, thread) }
      end
    end

    #
    # Fetch archived private threads in the channel.
    # @macro async
    # @macro http
    #
    # @return [Array<Discorb::ThreadChannel>] The archived private threads in the channel.
    #
    def fetch_archived_private_threads
      Async do
        _resp, data = @client.internet.get("/channels/#{@id}/threads/archived/private").wait
        data.map { |thread| Channel.make_channel(@client, thread) }
      end
    end

    #
    # Fetch joined archived private threads in the channel.
    # @macro async
    # @macro http
    #
    # @param [Integer] limit The limit of threads to fetch.
    # @param [Time] before <description>
    #
    # @return [Array<Discorb::ThreadChannel>] The joined archived private threads in the channel.
    #
    def fetch_joined_archived_private_threads(limit: nil, before: nil)
      Async do
        if limit.nil?
          before = 0
          threads = []
          loop do
            _resp, data = @client.internet.get("/channels/#{@id}/users/@me/threads/archived/private?before=#{before}").wait
            threads += data[:threads].map { |thread| Channel.make_channel(@client, thread) }
            before = data[:threads][-1][:id]

            break unless data[:has_more]
          end
          threads
        else
          _resp, data = @client.internet.get("/channels/#{@id}/users/@me/threads/archived/private?limit=#{limit}&before=#{before}").wait
          data.map { |thread| Channel.make_channel(@client, thread) }
        end
      end
    end

    private

    def _set_data(data)
      @topic = data[:topic]
      @nsfw = data[:nsfw]
      @last_message_id = data[:last_message_id]
      @rate_limit_per_user = data[:rate_limit_per_user]
      @last_pin_timestamp = data[:last_pin_timestamp] && Time.iso8601(data[:last_pin_timestamp])
      super
    end
  end

  #
  # Represents a news channel (announcement channel).
  #
  class NewsChannel < TextChannel
    include Messageable

    @channel_type = 5
  end

  #
  # Represents a voice channel.
  # @todo Implement connecting to voice channel.
  #
  class VoiceChannel < GuildChannel
    # @return [Integer] The bitrate of the voice channel.
    attr_reader :bitrate
    # @return [Integer] The user limit of the voice channel.
    # @return [nil] If the user limit is not set.
    attr_reader :user_limit

    @channel_type = 2
    #
    # Edit the voice channel.
    # @macro async
    # @macro http
    # @macro edit
    #
    # @param [String] name The name of the voice channel.
    # @param [Integer] position The position of the voice channel.
    # @param [Integer] bitrate The bitrate of the voice channel.
    # @param [Integer] user_limit The user limit of the voice channel.
    # @param [Symbol] rtc_region The region of the voice channel.
    # @param [String] reason The reason of editing the voice channel.
    #
    # @return [self] The edited voice channel.
    #
    def edit(name: :unset, position: :unset, bitrate: :unset, user_limit: :unset, rtc_region: :unset, reason: nil)
      Async do
        payload = {}
        payload[:name] = name if name != :unset
        payload[:position] = position if position != :unset
        payload[:bitrate] = bitrate if bitrate != :unset
        payload[:user_limit] = user_limit if user_limit != :unset
        payload[:rtc_region] = rtc_region if rtc_region != :unset

        @client.internet.patch("/channels/#{@id}", payload, audit_log_reason: reason).wait
        self
      end
    end

    alias modify edit

    private

    def _set_data(data)
      @bitrate = data[:bitrate]
      @user_limit = (data[:user_limit]).zero? ? nil : data[:user_limit]
      @rtc_region = data[:rtc_region]&.to_sym
      @video_quality_mode = data[:video_quality_mode] == 1 ? :auto : :full
      super
    end
  end

  #
  # Represents a stage channel.
  # @!attribute [r] stage_instance
  #   @return [Discorb::StageInstance] The stage instance of the channel.
  #
  class StageChannel < GuildChannel
    # @return [Integer] The bitrate of the voice channel.
    attr_reader :bitrate
    # @return [Integer] The user limit of the voice channel.
    attr_reader :user_limit
    # @!visibility private
    attr_reader :stage_instances

    @channel_type = 13
    # @!visibility private
    def initialize(...)
      @stage_instances = Dictionary.new
      super(...)
    end

    def stage_instance
      @stage_instances[0]
    end

    #
    # Edit the stage channel.
    # @macro async
    # @macro http
    # @macro edit
    #
    # @param [String] name The name of the stage channel.
    # @param [Integer] position The position of the stage channel.
    # @param [Integer] bitrate The bitrate of the stage channel.
    # @param [Symbol] rtc_region The region of the stage channel.
    # @param [String] reason The reason of editing the stage channel.
    #
    # @return [self] The edited stage channel.
    #
    def edit(name: :unset, position: :unset, bitrate: :unset, rtc_region: :unset, reason: nil)
      Async do
        payload = {}
        payload[:name] = name if name != :unset
        payload[:position] = position if position != :unset
        payload[:bitrate] = bitrate if bitrate != :unset
        payload[:rtc_region] = rtc_region if rtc_region != :unset
        @client.internet.patch("/channels/#{@id}", payload, audit_log_reason: reason).wait
        self
      end
    end

    alias modify edit

    #
    # Start a stage instance.
    # @macro async
    # @macro http
    #
    # @param [String] topic The topic of the stage instance.
    # @param [Boolean] public Whether the stage instance is public or not.
    # @param [String] reason The reason of starting the stage instance.
    #
    # @return [Discorb::StageInstance] The started stage instance.
    #
    def start(topic, public: false, reason: nil)
      Async do
        _resp, data = @client.internet.post("/stage-instances", { channel_id: @id, topic: topic, public: public ? 2 : 1 }, audit_log_reason: reason).wait
        StageInstance.new(@client, data)
      end
    end

    #
    # Fetch a current stage instance.
    # @macro async
    # @macro http
    #
    # @return [StageInstance] The current stage instance.
    # @return [nil] If there is no current stage instance.
    #
    def fetch_stage_instance
      Async do
        _resp, data = @client.internet.get("/stage-instances/#{@id}").wait
      rescue Discorb::NotFoundError
        nil
      else
        StageInstance.new(@client, data)
      end
    end

    private

    def _set_data(data)
      @bitrate = data[:bitrate]
      @user_limit = data[:user_limit]
      @topic = data[:topic]
      @rtc_region = data[:rtc_region]&.to_sym
      super
    end
  end

  #
  # Represents a thread.
  # @abstract
  # @!attribute [r] parent
  #   @macro client_cache
  #   @return [Discorb::GuildChannel] The parent channel of the thread.
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

    include Messageable
    @channel_type = nil

    # @!visibility private
    def initialize(client, data, no_cache: false)
      @members = Dictionary.new
      super
      @client.channels[@parent_id].threads[@id] = self

      @client.channels[@id] = self unless no_cache
    end

    #
    # Edit the thread.
    # @macro async
    # @macro http
    # @macro edit
    #
    # @param [String] name The name of the thread.
    # @param [Boolean] archived Whether the thread is archived or not.
    # @param [Integer] auto_archive_duration The auto archive duration in seconds.
    # @param [Integer] archive_in Alias of `auto_archive_duration`.
    # @param [Boolean] locked Whether the thread is locked or not.
    # @param [String] reason The reason of editing the thread.
    #
    # @return [self] The edited thread.
    #
    # @see #archive
    # @see #lock
    # @see #unarchive
    # @see #unlock
    #
    def edit(name: :unset, archived: :unset, auto_archive_duration: :unset, archive_in: :unset, locked: :unset, reason: nil)
      Async do
        payload = {}
        payload[:name] = name if name != :unset
        payload[:archived] = archived if archived != :unset
        auto_archive_duration ||= archive_in
        payload[:auto_archive_duration] = auto_archive_duration if auto_archive_duration != :unset
        payload[:locked] = locked if locked != :unset
        @client.internet.patch("/channels/#{@id}", payload, audit_log_reason: reason).wait
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
      @members[@client.user.id]
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

    def add_member(member = :me)
      Async do
        if member == :me
          @client.internet.post("/channels/#{@id}/thread-members/@me").wait
        else
          @client.internet.post("/channels/#{@id}/thread-members/#{Utils.try(member, :id)}").wait
        end
      end
    end

    alias join add_member

    def remove_member(member = :me)
      Async do
        if member == :me
          @client.internet.delete("/channels/#{@id}/thread-members/@me").wait
        else
          @client.internet.delete("/channels/#{@id}/thread-members/#{Utils.try(member, :id)}").wait
        end
      end
    end

    alias leave remove_member

    def fetch_members
      Async do
        _resp, data = @client.internet.get("/channels/#{@id}/thread-members").wait
        data.map { |d| @members[d[:id]] = Member.new(@client, d) }
      end
    end

    class Public < ThreadChannel
      @channel_type = 11
    end

    class Private < ThreadChannel
      @channel_type = 12
    end

    class << self
      attr_reader :channel_type
    end

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

  class CategoryChannel < GuildChannel
    attr_reader :channels

    @channel_type = 4

    def text_channels
      @channels.filter { |c| c.is_a? TextChannel }
    end

    def voice_channels
      @channels.filter { |c| c.is_a? VoiceChannel }
    end

    def news_channel
      @channels.filter { |c| c.is_a? NewsChannel }
    end

    def stage_channels
      @channels.filter { |c| c.is_a? StageChannel }
    end

    def create_text_channel(*args, **kwargs)
      guild.create_text_channel(*args, parent: self, **kwargs)
    end

    def create_voice_channel(*args, **kwargs)
      guild.create_voice_channel(*args, parent: self, **kwargs)
    end

    def create_news_channel(*args, **kwargs)
      guild.create_news_channel(*args, parent: self, **kwargs)
    end

    def create_stage_channel(*args, **kwargs)
      guild.create_stage_channel(*args, parent: self, **kwargs)
    end

    private

    def _set_data(data)
      @channels = @client.channels.values.filter { |channel| channel.parent == self }
      super
    end
  end
end
