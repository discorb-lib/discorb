# frozen_string_literal: true


module Discorb
  #
  # Represents invite of discord.
  #
  class Invite < DiscordModel
    attr_reader :code, :target_type, :target_user,
                :approximate_presence_count, :approximate_member_count,
                :expires_at, :uses, :max_uses, :max_age, :created_at

    @target_types = {
      nil => :voice,
      1 => :stream,
      2 => :guild
    }.freeze

    # @!visibility private
    def initialize(client, data, gateway)
      @client = client
      @data = data[:data]
      _set_data(data, gateway)
    end

    #
    # Channel of the invite.
    #
    # @!macro client_cache
    # @!macro async
    # @return [Async::Task<Discorb::Channel>]
    #
    def channel
      @client.channels[@channel_data[:id]]
    end

    #
    # Guild of the invite.
    #
    # @!macro client_cache
    # @!macro async
    # @return [Async::Task<Discorb::Guild>]
    #
    def guild
      @client.guilds[@guild_data[:id]]
    end

    # Full url of invite.
    def url
      "https://discord.gg/#{@code}"
    end

    # Returns the number of uses of invite.
    # @return [Integer]
    def remain_uses
      @max_uses && @max_uses - @uses
    end

    # Whether the invite is temporary.
    # @return [Boolean]
    def temporary?
      @temporary
    end

    # |task|
    # Delete the invite.
    def delete!(reason: nil)
      Async do
        @client.internet.delete("/invites/#{@code}", audit_log_reason: reason)
      end
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
        @approximate_presence_count = data[:approximate_presence_count]
        @approximate_member_count = data[:approximate_member_count]
        @expires_at = data[:expires_at] && Time.iso8601(data[:expires_at])
      end
      @inviter_data = data[:inviter]
      @target_type = self.class.target_types[data[:target_type]]
      @target_user = @client.users[data[:target_user][:id]] || User.new(@client, data[:target_user]) if data[:target_user]
      # @target_application = nil

      # @stage_instance = data[:stage_instance] && Invite::StageInstance.new(self, data[:stage_instance])
      return unless data.key?(:uses)

      @uses = data[:uses]
      @max_uses = data[:max_uses]
      @max_age = data[:max_age]
      @temporary = data[:temporary]
      @created_at = Time.iso8601(data[:created_at])
    end

    class << self
      # @!visibility private
      attr_reader :target_types
    end
  end
end
