# frozen_string_literal: true

require "async"

module Discorb
  #
  # Represents a channel of Discord.
  # @abstract
  #
  class Channel < DiscordModel
    # @return [Discorb::Snowflake] The ID of the channel.
    attr_reader :id
    # @return [String] The name of the channel.
    attr_reader :name

    # @!attribute [r] type
    #   @return [Integer] The type of the channel as integer.

    @channel_type = nil
    @subclasses = []

    # @private
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

    # @private
    def self.descendants
      ObjectSpace.each_object(Class).select { |klass| klass < self }
    end

    # @private
    def self.make_channel(client, data, no_cache: false)
      descendants.each do |klass|
        return klass.new(client, data, no_cache: no_cache) if !klass.channel_type.nil? && klass.channel_type == data[:type]
      end
      client.log.warn("Unknown channel type #{data[:type]}, initialized GuildChannel")
      GuildChannel.new(client, data)
    end

    class << self
      # @private
      attr_reader :channel_type
    end

    def type
      self.class.channel_type
    end

    # @private
    def channel_id
      Async do
        @id
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
  #
  class GuildChannel < Channel
    # @return [Integer] The position of the channel as integer.
    attr_reader :position
    # @return [Hash{Discorb::Role, Discorb::Member => PermissionOverwrite}] The permission overwrites of the channel.
    attr_reader :permission_overwrites

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
    # @async
    #
    # @param [String] reason The reason of deleting the channel.
    #
    # @return [Async::Task<self>] The deleted channel.
    #
    def delete!(reason: nil)
      Async do
        @client.http.request(Route.new(base_url.wait.to_s, "//webhooks/:webhook_id/:token", :delete), audit_log_reason: reason).wait
        @deleted = true
        self
      end
    end

    alias close! delete!
    alias destroy! delete!

    #
    # Moves the channel to another position.
    # @async
    #
    # @param [Integer] position The position to move the channel.
    # @param [Boolean] lock_permissions Whether to lock the permissions of the channel.
    # @param [Discorb::CategoryChannel] parent The parent of channel.
    # @param [String] reason The reason of moving the channel.
    #
    # @return [Async::Task<self>] The moved channel.
    #
    def move(position, lock_permissions: false, parent: Discorb::Unset, reason: nil)
      Async do
        payload = {
          position: position,
        }
        payload[:lock_permissions] = lock_permissions
        payload[:parent_id] = parent&.id if parent != Discorb::Unset
        @client.http.request(Route.new("/guilds/#{@guild_id}/channels", "//guilds/:guild_id/channels", :patch), payload, audit_log_reason: reason).wait
      end
    end

    private

    def _set_data(data)
      @guild_id = data[:guild_id]
      @position = data[:position]
      @permission_overwrites = if data[:permission_overwrites]
          data[:permission_overwrites].to_h do |ow|
            [(ow[:type] == 1 ? guild.roles : guild.members)[ow[:id]], PermissionOverwrite.new(ow[:allow], ow[:deny])]
          end
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

    include Messageable

    @channel_type = 0

    # @!attribute [r] threads
    #   @return [Array<Discorb::ThreadChannel>] The threads in the channel.
    def threads
      guild.threads.select { |thread| thread.parent == self }
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
    # @param [Boolean] nsfw Whether the channel is nsfw.
    # @param [Boolean] announce Whether the channel is announce channel.
    # @param [Integer] rate_limit_per_user The rate limit per user (Slowmode) in the channel.
    # @param [Integer] slowmode Alias of `rate_limit_per_user`.
    # @param [Integer] default_auto_archive_duration The default auto archive duration of the channel.
    # @param [Integer] archive_in Alias of `default_auto_archive_duration`.
    # @param [String] reason The reason of editing the channel.
    #
    # @return [Async::Task<self>] The edited channel.
    #
    def edit(name: Discorb::Unset, position: Discorb::Unset, category: Discorb::Unset, parent: Discorb::Unset,
             topic: Discorb::Unset, nsfw: Discorb::Unset, announce: Discorb::Unset,
             rate_limit_per_user: Discorb::Unset, slowmode: Discorb::Unset, default_auto_archive_duration: Discorb::Unset,
             archive_in: Discorb::Unset, reason: nil)
      Async do
        payload = {}
        payload[:name] = name if name != Discorb::Unset
        payload[:announce] = announce ? 5 : 0 if announce != Discorb::Unset
        payload[:position] = position if position != Discorb::Unset
        payload[:topic] = topic || "" if topic != Discorb::Unset
        payload[:nsfw] = nsfw if nsfw != Discorb::Unset

        slowmode = rate_limit_per_user if slowmode == Discorb::Unset
        payload[:rate_limit_per_user] = slowmode || 0 if slowmode != Discorb::Unset
        parent = category if parent == Discorb::Unset
        payload[:parent_id] = parent&.id if parent != Discorb::Unset

        default_auto_archive_duration ||= archive_in
        payload[:default_auto_archive_duration] = default_auto_archive_duration if default_auto_archive_duration != Discorb::Unset

        @client.http.request(Route.new("/channels/#{@id}", "//channels/:channel_id", :patch), payload, audit_log_reason: reason).wait
        self
      end
    end

    alias modify edit

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
        _resp, data = @client.http.request(Route.new("/channels/#{@id}/webhooks", "//channels/:channel_id/webhooks", :post), payload).wait
        Webhook.new([@client, data])
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
        _resp, data = @client.http.request(Route.new("/channels/#{@id}/webhooks", "//channels/:channel_id/webhooks", :get)).wait
        data.map { |webhook| Webhook.new([@client, webhook]) }
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

        @client.http.request(Route.new("/channels/#{@id}/messages/bulk-delete", "//channels/:channel_id/messages/bulk-delete", :post), { messages: message_ids }).wait
      end
    end

    alias bulk_delete! delete_messages!
    alias destroy_messages! delete_messages!

    #
    # Set the channel's permission overwrite.
    # @async
    #
    # @param [Discorb::Role, Discorb::Member] target The target of the overwrite.
    # @param [String] reason The reason of setting the overwrite.
    # @param [{Symbol => Boolean}] perms The permission overwrites to replace.
    #
    # @return [Async::Task<void>] The task.
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
        @client.http.request(Route.new("/channels/#{@id}/permissions/#{target.id}", "//channels/:channel_id/permissions/:target_id", :put), payload, audit_log_reason: reason).wait
      end
    end

    alias modify_permissions set_permissions
    alias modify_permisssion set_permissions
    alias edit_permissions set_permissions
    alias edit_permission set_permissions

    #
    # Delete the channel's permission overwrite.
    # @async
    #
    # @param [Discorb::Role, Discorb::Member] target The target of the overwrite.
    # @param [String] reason The reason of deleting the overwrite.
    #
    # @return [Async::Task<void>] The task.
    #
    def delete_permissions(target, reason: nil)
      Async do
        @client.http.request(Route.new("/channels/#{@id}/permissions/#{target.id}", "//channels/:channel_id/permissions/:target_id", :delete), audit_log_reason: reason).wait
      end
    end

    alias delete_permission delete_permissions
    alias destroy_permissions delete_permissions
    alias destroy_permission delete_permissions

    #
    # Fetch the channel's invites.
    # @async
    #
    # @return [Async::Task<Array<Discorb::Invite>>] The invites in the channel.
    #
    def fetch_invites
      Async do
        _resp, data = @client.http.request(Route.new("/channels/#{@id}/invites", "//channels/:channel_id/invites", :get)).wait
        data.map { |invite| Invite.new(@client, invite) }
      end
    end

    #
    # Create an invite in the channel.
    # @async
    #
    # @param [Integer] max_age The max age of the invite.
    # @param [Integer] max_uses The max uses of the invite.
    # @param [Boolean] temporary Whether the invite is temporary.
    # @param [Boolean] unique Whether the invite is unique.
    #   @note if it's `false` it may return existing invite.
    # @param [String] reason The reason of creating the invite.
    #
    # @return [Async::Task<Invite>] The created invite.
    #
    def create_invite(max_age: nil, max_uses: nil, temporary: false, unique: false, reason: nil)
      Async do
        _resp, data = @client.http.request(Route.new("/channels/#{@id}/invites", "//channels/:channel_id/invites", :post), {
          max_age: max_age,
          max_uses: max_uses,
          temporary: temporary,
          unique: unique,
        }, audit_log_reason: reason).wait
        Invite.new(@client, data, false)
      end
    end

    #
    # Follow the existing announcement channel.
    # @async
    #
    # @param [Discorb::NewsChannel] target The channel to follow.
    # @param [String] reason The reason of following the channel.
    #
    # @return [Async::Task<void>] The task.
    #
    def follow_from(target, reason: nil)
      Async do
        @client.http.request(Route.new("/channels/#{target.id}/followers", "//channels/:channel_id/followers", :post), { webhook_channel_id: @id }, audit_log_reason: reason).wait
      end
    end

    #
    # Follow the existing announcement channel from self.
    # @async
    #
    # @param [Discorb::TextChannel] target The channel to follow to.
    # @param [String] reason The reason of following the channel.
    #
    # @return [Async::Task<void>] The task.
    #
    def follow_to(target, reason: nil)
      Async do
        @client.http.request(Route.new("/channels/#{@id}/followers", "//channels/:channel_id/followers", :post), { webhook_channel_id: target.id }, audit_log_reason: reason).wait
      end
    end

    #
    # Start thread in the channel.
    # @async
    #
    # @param [String] name The name of the thread.
    # @param [Discorb::Message] message The message to start the thread.
    # @param [Integer] auto_archive_duration The duration of auto-archiving.
    # @param [Boolean] public Whether the thread is public.
    # @param [Integer] rate_limit_per_user The rate limit per user.
    # @param [Integer] slowmode Alias of `rate_limit_per_user`.
    # @param [String] reason The reason of starting the thread.
    #
    # @return [Async::Task<Discorb::ThreadChannel>] The started thread.
    #
    def start_thread(name, message: nil, auto_archive_duration: 1440, public: true, rate_limit_per_user: nil, slowmode: nil, reason: nil)
      Async do
        _resp, data = if message.nil?
            @client.http.request(Route.new("/channels/#{@id}/threads", "//channels/:channel_id/threads", :post), {
              name: name,
              auto_archive_duration: auto_archive_duration,
              type: public ? 11 : 10,
              rate_limit_per_user: rate_limit_per_user || slowmode,
            },
                                 audit_log_reason: reason).wait
          else
            @client.http.request(Route.new("/channels/#{@id}/messages/#{Utils.try(message, :id)}/threads", "//channels/:channel_id/messages/:message_id/threads", :post), {
              name: name, auto_archive_duration: auto_archive_duration,
            }, audit_log_reason: reason).wait
          end
        Channel.make_channel(@client, data)
      end
    end

    alias create_thread start_thread

    #
    # Fetch archived threads in the channel.
    # @async
    #
    # @return [Async::Task<Array<Discorb::ThreadChannel>>] The archived threads in the channel.
    #
    def fetch_archived_public_threads
      Async do
        _resp, data = @client.http.request(Route.new("/channels/#{@id}/threads/archived/public", "//channels/:channel_id/threads/archived/public", :get)).wait
        data.map { |thread| Channel.make_channel(@client, thread) }
      end
    end

    #
    # Fetch archived private threads in the channel.
    # @async
    #
    # @return [Async::Task<Array<Discorb::ThreadChannel>>] The archived private threads in the channel.
    #
    def fetch_archived_private_threads
      Async do
        _resp, data = @client.http.request(Route.new("/channels/#{@id}/threads/archived/private", "//channels/:channel_id/threads/archived/private", :get)).wait
        data.map { |thread| Channel.make_channel(@client, thread) }
      end
    end

    #
    # Fetch joined archived private threads in the channel.
    # @async
    #
    # @param [Integer] limit The limit of threads to fetch.
    # @param [Time] before <description>
    #
    # @return [Async::Task<Array<Discorb::ThreadChannel>>] The joined archived private threads in the channel.
    #
    def fetch_joined_archived_private_threads(limit: nil, before: nil)
      Async do
        if limit.nil?
          before = 0
          threads = []
          loop do
            _resp, data = @client.http.request(Route.new("/channels/#{@id}/users/@me/threads/archived/private?before=#{before}", "//channels/:channel_id/users/@me/threads/archived/private", :get)).wait
            threads += data[:threads].map { |thread| Channel.make_channel(@client, thread) }
            before = data[:threads][-1][:id]

            break unless data[:has_more]
          end
          threads
        else
          _resp, data = @client.http.request(Route.new("/channels/#{@id}/users/@me/threads/archived/private?limit=#{limit}&before=#{before}", "//channels/:channel_id/users/@me/threads/archived/private", :get)).wait
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
  #
  class VoiceChannel < GuildChannel
    # @return [Integer] The bitrate of the voice channel.
    attr_reader :bitrate
    # @return [Integer] The user limit of the voice channel.
    # @return [nil] If the user limit is not set.
    attr_reader :user_limit

    # @!attribute [r] members
    #   @return [Array<Discorb::Member>] The members in the voice channel.
    # @!attribute [r] voice_states
    #   @return [Array<Discorb::VoiceState>] The voice states associated with the voice channel.

    include Connectable

    @channel_type = 2
    #
    # Edit the voice channel.
    # @async
    # @macro edit
    #
    # @param [String] name The name of the voice channel.
    # @param [Integer] position The position of the voice channel.
    # @param [Integer] bitrate The bitrate of the voice channel.
    # @param [Integer] user_limit The user limit of the voice channel.
    # @param [Symbol] rtc_region The region of the voice channel.
    # @param [String] reason The reason of editing the voice channel.
    #
    # @return [Async::Task<self>] The edited voice channel.
    #
    def edit(name: Discorb::Unset, position: Discorb::Unset, bitrate: Discorb::Unset, user_limit: Discorb::Unset, rtc_region: Discorb::Unset, reason: nil)
      Async do
        payload = {}
        payload[:name] = name if name != Discorb::Unset
        payload[:position] = position if position != Discorb::Unset
        payload[:bitrate] = bitrate if bitrate != Discorb::Unset
        payload[:user_limit] = user_limit if user_limit != Discorb::Unset
        payload[:rtc_region] = rtc_region if rtc_region != Discorb::Unset

        @client.http.request(Route.new("/channels/#{@id}", "//channels/:channel_id", :patch), payload, audit_log_reason: reason).wait
        self
      end
    end

    alias modify edit

    def voice_states
      guild.voice_states.select { |state| state.channel&.id == @id }
    end

    def members
      voice_states.map(&:member)
    end

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
  #
  class StageChannel < GuildChannel
    # @return [Integer] The bitrate of the voice channel.
    attr_reader :bitrate
    # @return [Integer] The user limit of the voice channel.
    attr_reader :user_limit
    # @private
    attr_reader :stage_instances

    include Connectable

    # @!attribute [r] stage_instance
    #   @return [Discorb::StageInstance] The stage instance of the channel.

    @channel_type = 13
    # @private
    def initialize(...)
      @stage_instances = Dictionary.new
      super(...)
    end

    def stage_instance
      @stage_instances[0]
    end

    #
    # Edit the stage channel.
    # @async
    # @macro edit
    #
    # @param [String] name The name of the stage channel.
    # @param [Integer] position The position of the stage channel.
    # @param [Integer] bitrate The bitrate of the stage channel.
    # @param [Symbol] rtc_region The region of the stage channel.
    # @param [String] reason The reason of editing the stage channel.
    #
    # @return [Async::Task<self>] The edited stage channel.
    #
    def edit(name: Discorb::Unset, position: Discorb::Unset, bitrate: Discorb::Unset, rtc_region: Discorb::Unset, reason: nil)
      Async do
        payload = {}
        payload[:name] = name if name != Discorb::Unset
        payload[:position] = position if position != Discorb::Unset
        payload[:bitrate] = bitrate if bitrate != Discorb::Unset
        payload[:rtc_region] = rtc_region if rtc_region != Discorb::Unset
        @client.http.request(Route.new("/channels/#{@id}", "//channels/:channel_id", :patch), payload, audit_log_reason: reason).wait
        self
      end
    end

    alias modify edit

    #
    # Start a stage instance.
    # @async
    #
    # @param [String] topic The topic of the stage instance.
    # @param [Boolean] public Whether the stage instance is public or not.
    # @param [String] reason The reason of starting the stage instance.
    #
    # @return [Async::Task<Discorb::StageInstance>] The started stage instance.
    #
    def start(topic, public: false, reason: nil)
      Async do
        _resp, data = @client.http.request(Route.new("/stage-instances", "//stage-instances", :post), { channel_id: @id, topic: topic, public: public ? 2 : 1 }, audit_log_reason: reason).wait
        StageInstance.new(@client, data)
      end
    end

    #
    # Fetch a current stage instance.
    # @async
    #
    # @return [Async::Task<StageInstance>] The current stage instance.
    # @return [Async::Task<nil>] If there is no current stage instance.
    #
    def fetch_stage_instance
      Async do
        _resp, data = @client.http.request(Route.new("/stage-instances/#{@id}", "//stage-instances/:stage_instance_id", :get)).wait
      rescue Discorb::NotFoundError
        nil
      else
        StageInstance.new(@client, data)
      end
    end

    def voice_states
      guild.voice_states.select { |state| state.channel&.id == @id }
    end

    def members
      voice_states.map(&:member)
    end

    def speakers
      voice_states.filter { |state| !state.suppress? }.map(&:member)
    end

    def audiences
      voice_states.filter(&:suppress?).map(&:member)
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

    # @private
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

  #
  # Represents a category in a guild.
  #
  class CategoryChannel < GuildChannel
    @channel_type = 4

    def channels
      @client.channels.values.filter { |channel| channel.parent == self }
    end

    def text_channels
      channels.filter { |c| c.is_a? TextChannel }
    end

    def voice_channels
      channels.filter { |c| c.is_a? VoiceChannel }
    end

    def news_channel
      channels.filter { |c| c.is_a? NewsChannel }
    end

    def stage_channels
      channels.filter { |c| c.is_a? StageChannel }
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
  end

  #
  # Represents a DM channel.
  #
  class DMChannel < Channel
    include Messageable

    # @private
    def channel_id
      Async do
        @id
      end
    end

    private

    def _set_data(data)
      @id = Snowflake.new(data)
    end
  end
end
