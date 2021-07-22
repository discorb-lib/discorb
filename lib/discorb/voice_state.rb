# frozen_string_literal: true

require 'time'
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
      @guild_id ? @client.guilds[@guild_id] : nil
    end

    def channel
      @channel_id ? @client.channels[@channel_id] : nil
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
      @request_to_speak_timestamp = data[:request_to_speak_timestamp] ? Time.iso8601(data[:request_to_speak_timestamp]) : nil
    end
  end
end
