# frozen_string_literal: true

require_relative 'common'
require_relative 'user'

module Discorb
  class Invite < DiscordModel
    attr_reader :code, :target_type, :target_user, :target_application,
                :approximate_presence_count, :approximate_member_count,
                :expires_at, :stage_instance, :uses, :max_uses, :max_age, :temporary, :created_at

    @target_types = {
      nil => :voice,
      1 => :stream,
      2 => :guild
    }.freeze
    def initialize(client, data, gateway)
      @client = client
      @data = data[:data]
      _set_data(data, gateway)
    end

    def channel
      @client.channels[@channel_data[:id]]
    end

    def guild
      @client.guilds[@guild_data[:id]]
    end

    private

    def _set_data(data, gateway)
      @code = data[:code]
      if gateway
        @channel_data = { id: data[:channel_id] }
        @guild_data = { id: data[:guild_id] }
      else
        @guild_data = data[:guild]
        @channel_data = data[:channel]
        @approximate_presence_count = @data[:approximate_presence_count]
        @approximate_member_count = @data[:approximate_member_count]
        @expires_at = Time.iso8601(data[:expires_at])
      end
      @inviter_data = @data[:inviter]
      @target_type = self.class.target_types[@data[:target_type]]
      @target_user = @client.users[@data[:target_user][:id]] || User.new(@client, @data[:target_user]) if @data[:target_user]
      @target_application = nil # TODO: Application

      @stage_instance = nil # TODO: StageInstance
      return unless data.has?(:uses)

      @uses = data[:uses]
      @max_uses = data[:max_uses]
      @max_age = data[:max_age]
      @temporary = data[:temporary]
      @created_at = Time.iso8601(data[:created_at])
    end

    class << self
      attr_reader :target_types
    end
  end
end
