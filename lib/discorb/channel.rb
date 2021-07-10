# frozen_string_literal: true

require 'time'
require 'async'
require_relative 'modules'
require_relative 'flag'
require_relative 'common'
require_relative 'error'

module Discorb
  class Channel < DiscordModel
    attr_reader :id, :name, :channel_type, :_data

    @channel_type = nil
    @subclasses = []

    def initialize(client, data)
      @client = client
      @_data = {}
      _set_data(data)
    end

    def ==(other)
      @id == other.id
    end

    def inspect
      "#<#{self.class} \"##{@name}\" id=#{@id}>"
    end

    def self.descendants
      ObjectSpace.each_object(Class).select { |klass| klass < self }
    end

    def self.make_channel(client, data)
      descendants.each do |klass|
        return klass.new(client, data) if !klass.channel_type.nil? && klass.channel_type == data[:type]
      end
      @client.log.warn("Unknown channel type #{data[:type]}, initialized GuildChannel")
      GuildChannel.new(client, data)
    end

    class << self
      attr_reader :channel_type
    end

    def type
      self.class.channel_type
    end

    def post_url
      "/channels/#{@id}/messages"
    end

    # @!visibility private
    def _set_data(data)
      @id = Snowflake.new(data[:id])
      @name = data[:name]
      @client.channels[@id] = self
      @_data.update(data)
    end
  end

  class GuildChannel < Channel
    attr_reader :position, :permission_overwrites

    include Comparable
    @channel_type = nil

    def <=>(other)
      @position <=> other.position
    end

    def to_s
      "<##{@id}>"
    end

    def parent
      return nil unless @parent_id

      @client.channels[@parent_id]
    end

    alias category parent

    def guild
      @client.guilds[@guild]
    end

    def inspect
      "#<#{self.class} \"##{@name}\" id=#{@id}>"
    end

    # @!visibility private
    def _set_data(data)
      @guild_id = data[:guild_id]
      @position = data[:position]
      @permission_overwrites = data[:permission_overwrites].map do |ow|
        [(ow[:type] == 1 ? guild.roles : guild.members)[ow[:id]], PermissionOverwrite.new(ow[:allow], ow[:deny])]
      end.to_h
      @parent_id = data[:parent_id]

      super
    end
  end

  class TextChannel < GuildChannel
    attr_reader :topic, :nsfw, :last_message_id, :rate_limit_per_user, :last_pin_timestamp, :threads

    include Messageable

    @channel_type = 0

    alias slowmode rate_limit_per_user
    def initialize(client, data)
      super
      @threads = []
    end

    def edit(name: nil, announce: nil, position: nil, topic: nil, nsfw: nil, slowmode: nil, category: nil, parent: nil)
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

        @client.internet.patch("/channels/#{@id}", payload)
      end
    end

    def fetch_message(id)
      Async do
        _resp, data = @client.internet.get("/channels/#{@id}/messages/#{id}").wait
        Message.new(@client, data)
      end
    end

    # @!visibility private
    def _set_data(data)
      @topic = data[:topic]
      @nsfw = data[:nsfw]
      @last_message_id = data[:last_message_id]
      @rate_limit_per_user = data[:rate_limit_per_user]
      @last_pin_timestamp = data[:last_pin_timestamp] ? Time.iso8601(data[:last_pin_timestamp]) : nil
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
    def edit(name: nil, position: nil, bitrate: nil, user_limit: nil, rtc_region: nil)
      Async do
        payload = {}
        payload[:name] = name if name
        payload[:position] = position if position
        payload[:bitrate] = bitrate unless bitrate.nil?
        payload[:user_limit] = user_limit == false ? nil : user_limit unless user_limit.nil?
        payload[:rtc_region] = rtc_region == false ? nil : rtc_region unless rtc_region.nil?

        @client.internet.patch("/channels/#{@id}", payload)
      end
    end

    # @!visibility private
    def _set_data(data)
      @bitrate = data[:bitrate]
      @user_limit = (data[:user_limit]).zero? ? nil : data[:user_limit]
      @rtc_region = data[:rtc_region]&.to_sym
      @video_quality_mode = data[:video_quality_mode] == 1 ? :auto : :full
      super
    end
  end

  class StageChannel < GuildChannel
    attr_reader :bitrate, :user_limit

    @channel_type = 13
    def edit(name: nil, position: nil, bitrate: nil, user_limit: nil)
      Async do
        payload = {}
        payload[:name] = name if name
        payload[:position] = position if position
        payload[:bitrate] = bitrate unless bitrate.nil?
        payload[:user_limit] = user_limit unless user_limit.nil?
        @client.internet.patch("/channels/#{@id}", payload)
      end
    end

    # @!visibility private
    def _set_data(data)
      @bitrate = data[:bitrate]
      @user_limit = data[:user_limit]
      @topic = data[:topic]
      @rtc_region = data[:rtc_region]&.to_sym
      super
    end
  end

  class ThreadChannel < Channel
    attr_reader :id, :name, :type, :message_count, :member_count, :rate_limit_per_user

    include Messageable

    alias slowmode rate_limit_per_user
    @channel_type = nil

    def initialize(client, data)
      @client = client
      _set_data(data)
    end

    def ==(other)
      @id == other.id
    end

    def parent
      return nil unless @parent_id

      @client.channels[@parent_id]
    end

    alias channel parent

    def guild
      @client.guilds[@guild]
    end

    def owner
      guild.members[@owner_id]
    end

    def inspect
      "#<#{self.class} \"##{@name}\" id=#{@id}>"
    end

    class << self
      attr_reader :channel_type
    end
    def post_url
      "/channels/#{@id}/messages"
    end

    # @!visibility private
    def _set_data(data)
      @id = Snowflake.new(data[:id])
      @name = name
      @guild_id = data[:guild_id]
      @parent_id = data[:parent_id]
      @client.channels[@parent_id]&.threads&.push(self) unless @parent_id.nil?

      @client.channels[@id] = self
    end
  end

  class PublicThreadChannel < ThreadChannel
    attr_reader :bitrate, :user_limit

    @channel_type = 11
    def edit(name: nil, position: nil, bitrate: nil, user_limit: nil)
      Async do
        payload = {}
        payload[:name] = name if name
        payload[:position] = position if position
        payload[:bitrate] = bitrate unless bitrate.nil?
        payload[:user_limit] = user_limit unless user_limit.nil?

        @client.internet.patch("/channels/#{@id}", payload)
      end
    end

    # @!visibility private
    def _set_data(data)
      @bitrate = data[:bitrate]
      @user_limit = data[:user_limit]
      super
    end
  end

  class PrivateThreadChannel < ThreadChannel
    attr_reader :bitrate, :user_limit

    @channel_type = 12
    def edit(name: nil, position: nil, bitrate: nil, user_limit: nil)
      Async do
        payload = {}
        payload[:name] = name if name
        payload[:position] = position if position
        payload[:bitrate] = bitrate unless bitrate.nil?
        payload[:user_limit] = user_limit unless user_limit.nil?

        @client.internet.patch("/channels/#{@id}", payload)
      end
    end

    # @!visibility private
    def _set_data(data)
      @bitrate = data[:bitrate]
      @user_limit = data[:user_limit]
      super
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

    # @!visibility private
    def _set_data(data)
      @channels = @client.channels.values.filter { |channel| channel.parent == self }
      super
    end
  end
end
