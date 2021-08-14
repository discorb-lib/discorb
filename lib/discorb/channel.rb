# frozen_string_literal: true

require 'async'
require_relative 'modules'
require_relative 'flag'
require_relative 'common'
require_relative 'error'

module Discorb
  class Channel < DiscordModel
    attr_reader :id, :name, :channel_type

    @channel_type = nil
    @subclasses = []

    def initialize(client, data, no_cache: false)
      @client = client
      @data = {}
      @no_cache = no_cache
      _set_data(data)
    end

    def ==(other)
      return false unless other.respond_to?(:id)

      @id == other.id
    end

    def inspect
      "#<#{self.class} \"##{@name}\" id=#{@id}>"
    end

    def self.descendants
      ObjectSpace.each_object(Class).select { |klass| klass < self }
    end

    def self.make_channel(client, data, no_cache: false)
      descendants.each do |klass|
        return klass.new(client, data, no_cache: no_cache) if !klass.channel_type.nil? && klass.channel_type == data[:type]
      end
      client.log.warn("Unknown channel type #{data[:type]}, initialized GuildChannel")
      GuildChannel.new(client, data)
    end

    class << self
      attr_reader :channel_type
    end

    def type
      self.class.channel_type
    end

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

  class GuildChannel < Channel
    attr_reader :position, :permission_overwrites

    include Comparable
    @channel_type = nil

    def <=>(other)
      return 0  unless other.respond_to?(:position)

      @position <=> other.position
    end

    def ==(other)
      @id == other.id
    end

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

    def delete!(reason: nil)
      Async do
        @client.internet.delete(base_url.wait.to_s, audit_log_reason: reason).wait
        @deleted = true
        self
      end
    end

    alias close! delete!
    alias destroy! delete!

    def move(position, lock_permissions: false, parent: :unset, reason: nil)
      Async do
        payload = {
          position: position
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

  class TextChannel < GuildChannel
    attr_reader :topic, :nsfw, :last_message_id, :rate_limit_per_user, :last_pin_timestamp, :threads

    include Messageable

    @channel_type = 0

    alias slowmode rate_limit_per_user
    def initialize(client, data, no_cache: false)
      super
      @threads = Dictionary.new
    end

    def edit(name: :unset, position: :unset, category: :unset, parent: :unset,
             topic: :unset, nsfw: :unset, announce: :unset,
             slowmode: :unset, default_auto_archive_duration: :unset,
             archive_in: :unset, reason: nil)
      Async do
        payload = {}
        payload[:name] = name if name != :unset
        payload[:announce] = announce ? 5 : 0 if announce != :unset
        payload[:position] = position if position != :unset
        payload[:topic] = topic || '' if topic != :unset
        payload[:nsfw] = nsfw if nsfw != :unset

        payload[:rate_limit_per_user] = slowmode || 0 if slowmode != :unset
        parent ||= category
        payload[:parent_id] = parent&.id if parent != :unset

        default_auto_archive_duration ||= archive_in
        payload[:default_auto_archive_duration] = default_auto_archive_duration if default_auto_archive_duration != :unset

        @client.internet.patch("/channels/#{@id}", payload, audit_log_reason: reason).wait
        self
      end
    end
    alias modify edit

    def create_webhook(name, avatar: nil)
      Async do
        payload = {}
        payload[:name] = name
        payload[:avatar] = avatar.to_s if avatar
        _resp, data = @client.internet.post("/channels/#{@id}/webhooks", payload).wait
        Webhook.new([@client, data])
      end
    end

    def fetch_webhooks
      Async do
        _resp, data = @client.internet.get("/channels/#{@id}/webhooks").wait
        data.map { |webhook| Webhook.new([@client, webhook]) }
      end
    end

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
          type: target.is_a?(Member) ? 1 : 0
        }
        @client.internet.put("/channels/#{@id}/permissions/#{target.id}", payload, audit_log_reason: reason).wait
      end
    end
    alias modify_permissions set_permissions
    alias modify_permisssion set_permissions
    alias edit_permissions set_permissions
    alias edit_permission set_permissions

    def delete_permissions(target, reason: nil)
      Async do
        @client.internet.delete("/channels/#{@id}/permissions/#{target.id}", audit_log_reason: reason).wait
      end
    end
    alias delete_permission delete_permissions
    alias destroy_permissions delete_permissions
    alias destroy_permission delete_permissions

    def fetch_invites
      Async do
        _resp, data = @client.internet.get("/channels/#{@id}/invites").wait
        data.map { |invite| Invite.new(@client, invite) }
      end
    end

    def create_invite(max_age: nil, max_uses: nil, temporary: false, unique: false, reason: nil)
      Async do
        _resp, data = @client.internet.post("/channels/#{@id}/invites", {
                                              max_age: max_age,
                                              max_uses: max_uses,
                                              temporary: temporary,
                                              unique: unique
                                            }, audit_log_reason: reason).wait
        Invite.new(@client, data)
      end
    end

    def follow_from(target, reason: nil)
      Async do
        @client.internet.post("/channels/#{target.id}/followers", { webhook_channel_id: @id }, audit_log_reason: reason).wait
      end
    end

    def follow_to(target, reason: nil)
      Async do
        @client.internet.post("/channels/#{@id}/followers", { webhook_channel_id: target.id }, audit_log_reason: reason).wait
      end
    end

    def typing
      Async do |task|
        if block_given?
          begin
            post_task = task.async do |loop_task|
              @client.internet.post("/channels/#{@id}/typing", {})
              loop_task.sleep(5)
            end
            yield
          ensure
            post_task.stop
          end
        else
          @client.internet.post("/channels/#{@id}/typing").wait
        end
      end
    end

    def fetch_pins
      Async do
        _resp, data = @client.internet.get("/channels/#{@id}/pins").wait
        data.map { |pin| Message.new(@client, pin) }
      end
    end

    def pin_message(message, reason: nil)
      Async do
        @client.internet.put("/channels/#{@id}/pins/#{message.id}", {}, audit_log_reason: reason).wait
      end
    end

    def unpin_message(message, reason: nil)
      Async do
        @client.internet.delete("/channels/#{@id}/pins/#{message.id}", {}, audit_log_reason: reason).wait
      end
    end

    def start_thread(name, message: nil, auto_archive_duration: 1440, public: true, reason: nil)
      Async do
        _resp, data = if message.nil?
                        @client.internet.post("/channels/#{@id}/threads", {
                                                name: name, auto_archive_duration: auto_archive_duration, type: public ? 11 : 10
                                              },
                                              audit_log_reason: reason).wait
                      else
                        @client.internet.post("/channels/#{@id}/messages/#{Utils.try(message, :id)}/threads", {
                                                name: name, auto_archive_duration: auto_archive_duration
                                              }, audit_log_reason: reason).wait
                      end
        Channel.make_channel(@client, data)
      end
    end

    alias create_thread start_thread

    def fetch_archived_public_threads
      Async do
        _resp, data = @client.internet.get("/channels/#{@id}/threads/archived/public").wait
        data.map { |thread| Channel.make_channel(@client, thread) }
      end
    end

    def fetch_archived_private_threads
      Async do
        _resp, data = @client.internet.get("/channels/#{@id}/threads/archived/private").wait
        data.map { |thread| Channel.make_channel(@client, thread) }
      end
    end

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

  class NewsChannel < TextChannel
    include Messageable

    @channel_type = 5
  end

  class VoiceChannel < GuildChannel
    attr_reader :bitrate, :user_limit

    @channel_type = 2
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

  class StageChannel < GuildChannel
    attr_reader :bitrate, :user_limit, :stage_instances

    @channel_type = 13
    def initialize(...)
      @stage_instances = Dictionary.new
      super(...)
    end

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

    def start(topic, public: false, reason: nil)
      Async do
        _resp, data = @client.internet.post('/stage-instances', { channel_id: @id, topic: topic, public: public ? 2 : 1 }, audit_log_reason: reason).wait
        StageInstance.new(@client, data)
      end
    end

    def fetch_stage_instance
      Async do
        _resp, data = @client.internet.get("/stage-instances/#{@id}").wait
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

  class ThreadChannel < Channel
    attr_reader :id, :name, :type, :message_count, :member_count, :rate_limit_per_user, :members, :archived_timestamp, :auto_archive_duration

    include Messageable

    alias slowmode rate_limit_per_user
    alias archived_at archived_timestamp
    alias archive_in auto_archive_duration
    @channel_type = nil

    def initialize(client, data, no_cache: false)
      @members = Dictionary.new
      super
      @client.channels[@parent_id].threads[@id] = self

      @client.channels[@id] = self unless no_cache
    end

    def ==(other)
      @id == other.id
    end

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

    def archive(reason: nil)
      edit(archived: true, reason: reason)
    end

    def lock(reason: nil)
      edit(archived: true, locked: true, reason: reason)
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

    def archived?
      @archived
    end

    def locked?
      @locked
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
