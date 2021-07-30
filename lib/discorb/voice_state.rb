# frozen_string_literal: true

require_relative 'common'

module Discorb
  class VoiceState < DiscordModel
    attr_reader :guild_id, :channel_id, :user_id, :member, :session_id,
                :request_to_speak_timestamp

    def initialize(client, data)
      @client = client
      _set_data(data)
    end

    def deaf?
      @deaf || @self_deaf
    end

    def mute?
      @mute || @self_mute
    end

    def video?
      @self_video
    end

    def stream?
      @self_stream
    end
    alias live? stream?

    def server_deaf?
      @deaf
    end

    def server_mute?
      @mute
    end

    def self_deaf?
      @self_deaf
    end

    def self_mute?
      @self_mute
    end

    def supress?
      @suppress
    end

    def guild
      @guild_id && @client.guilds[@guild_id]
    end

    def channel
      @channel_id && @client.channels[@channel_id]
    end

    def user
      @client.users[@user_id]
    end

    private

    def _set_data(data)
      @data = data
      @guild_id = data[:guild_id]
      @channel_id = data[:channel_id]
      @user_id = data[:user_id]
      unless guild.nil?
        @member = if data.key?(:member)
                    guild.members[data[:user_id]] || Member.new(@client, @guild_id, data[:member][:user], data[:member])
                  else
                    guild.members[data[:user_id]]
                  end
      end
      @session_id = data[:session_id]
      @deaf = data[:deaf]
      @mute = data[:mute]
      @self_deaf = data[:self_deaf]
      @self_mute = data[:self_mute]
      @self_stream = data[:self_stream]
      @self_video = data[:self_video]
      @suppress = data[:suppress]
      @request_to_speak_timestamp = data[:request_to_speak_timestamp] && Time.iso8601(data[:request_to_speak_timestamp])
    end
  end

  class StageInstance < DiscordModel
    attr_reader :id, :topic, :privacy_level

    @privacy_level = {
      1 => :public,
      2 => :guild_only
    }

    def initialize(client, data, no_cache: false)
      @client = client
      @data = data
      _set_data(data)
      channel.stage_instances[@id] = self unless no_cache
    end

    def guild
      @client.guilds[@data[:guild_id]]
    end

    def channel
      @client.channels[@data[:channel_id]]
    end

    def discoverable?
      !@discoverable_disabled
    end

    def public?
      @privacy_level == :public
    end

    def guild_only?
      @privacy_level == :guild_only
    end

    def inspect
      "#<#{self.class} topic=#{@topic.inspect}>"
    end

    def edit(topic: nil, privacy_level: nil)
      Async do
        payload = {}
        payload[:topic] = topic if topic
        payload[:privacy_level] = self.class.privacy_level[privacy_level] if privacy_level
        @client.internet.edit("/stage-instances/#{@channel_id}", payload).wait
        self
      end
    end

    def delete!(reason: nil)
      Async do
        @client.internet.delete("/stage-instances/#{@channel_id}", reason: reason).wait
        self
      end
    end

    alias destroy! delete!
    alias end! delete!

    private

    def _set_data(data)
      @id = Snowflake.new(data[:id])
      @guild_id = Snowflake.new(data[:guild_id])
      @channel_id = Snowflake.new(data[:channel_id])
      @topic = data[:topic]
      @privacy_level = self.class.privacy_level[data[:privacy_level]]
      @discoverable_disabled = data[:discoverable_disabled]
    end

    class << self
      attr_reader :privacy_level
    end
  end
end
