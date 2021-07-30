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
      super == other
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

    def edit(name: nil, position: nil, category: nil, parent: nil,
             topic: nil, nsfw: nil, announce: nil,
             slowmode: nil, default_auto_archive_duration: nil,
             archive_in: nil, reason: nil)
      Async do
        payload = {}
        payload[:name] = name if name
        payload[:announce] = announce ? 5 : 0 unless announce.nil?
        payload[:position] = position if position
        payload[:topic] = topic || '' unless topic.nil?
        payload[:nsfw] = nsfw unless nsfw.nil?

        payload[:rate_limit_per_user] = slowmode || 0 unless slowmode.nil?
        parent ||= category
        payload[:parent_id] = parent.id unless parent.nil?

        default_auto_archive_duration ||= archive_in
        payload[:default_auto_archive_duration] = default_auto_archive_duration unless default_auto_archive_duration.nil?

        @client.internet.patch("/channels/#{@id}", payload, audit_log_reason: reason).wait
        self
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
    def edit(name: nil, position: nil, bitrate: nil, user_limit: nil, rtc_region: nil, reason: nil)
      Async do
        payload = {}
        payload[:name] = name if name
        payload[:position] = position if position
        payload[:bitrate] = bitrate unless bitrate.nil?
        payload[:user_limit] = user_limit == false ? nil : user_limit unless user_limit.nil?
        payload[:rtc_region] = rtc_region == false ? nil : rtc_region unless rtc_region.nil?

        @client.internet.patch("/channels/#{@id}", payload, audit_log_reason: reason).wait
        self
      end
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

  class StageChannel < GuildChannel
    attr_reader :bitrate, :user_limit, :stage_instances

    @channel_type = 13
    def initialize(...)
      @stage_instances = Dictionary.new
      super(...)
    end

    def edit(name: nil, position: nil, bitrate: nil, rtc_region: nil, reason: nil)
      Async do
        payload = {}
        payload[:name] = name if name
        payload[:position] = position if position
        payload[:bitrate] = bitrate unless bitrate.nil?
        payload[:rtc_region] = rtc_region unless rtc_region.nil?
        @client.internet.patch("/channels/#{@id}", payload, audit_log_reason: reason).wait
        self
      end
    end

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

    def edit(name: nil, archived: nil, auto_archive_duration: nil, archive_in: nil, locked: nil, reason: nil)
      Async do
        payload = {}
        payload[:name] = name if name
        payload[:archived] = archived unless archived.nil?
        auto_archive_duration ||= archive_in
        payload[:auto_archive_duration] = auto_archive_duration unless auto_archive_duration.nil?
        payload[:locked] = locked unless locked.nil?
        @client.internet.patch("/channels/#{@id}", payload, audit_log_reason: reason).wait
        self
      end
    end

    def archive!(reason: nil)
      edit(archived: true, reason: reason)
    end

    def lock!(reason: nil)
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

    def post_url
      "/channels/#{@id}/messages"
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
        # p data[:flags]
        # @flag = Flag.new(data[:flags])
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

      class Flag < Discorb::Flag
        @bits = {
          # TODO: Fill this
        }
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
      @archived_timestamp = Time.iso8601(data[:thread_metadata][:archived_timestamp]) if @archived
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

    private

    def _set_data(data)
      @channels = @client.channels.values.filter { |channel| channel.parent == self }
      super
    end
  end
end
