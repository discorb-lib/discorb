# frozen_string_literal: true

module Discorb
  #
  # Represents invite of discord.
  #
  class Invite < DiscordModel
    # @return [String] The code of invite.
    attr_reader :code

    # @return [:voice, :stream, :guild] The type of invite.
    attr_reader :target_type

    # @return [User] The user of invite.
    attr_reader :target_user

    # @return [Integer] The approximate number of online users of invite.
    attr_reader :approximate_presence_count

    # @return [Integer] The approximate number of members of invite.
    attr_reader :approximate_member_count

    # @return [Time] The time when invite expires.
    # @return [nil] The invite never expires.
    # @macro [new] nometa
    #   @return [nil] The invite doesn't have metadata.
    attr_reader :expires_at

    # @return [Integer] The number of uses of invite.
    # @macro nometa
    attr_reader :uses

    # @return [Integer] The maximum number of uses of invite.
    # @macro nometa
    attr_reader :max_uses

    # @return [Integer] Duration of invite in seconds.
    # @macro nometa
    attr_reader :max_age

    # @return [Time] The time when invite was created.
    # @macro nometa
    attr_reader :created_at

    # @!attribute [r] channel
    #   Channel of the invite.
    #
    #   @return [Discorb::Channel] Channel of invite.
    #   @macro client_cache
    #
    # @!attribute [r] guild
    #   Guild of the invite.
    #
    #   @return [Discorb::Guild] Guild of invite.
    #   @macro client_cache
    #
    # @!attribute [r] remain_uses
    #   Number of remaining uses of invite.
    #   @return [Integer] Number of remaining uses of invite.
    #
    # @!attribute [r] url
    #   Full url of invite.
    #   @return [String] Full url of invite.
    #
    # @!attribute [r] temporary?
    #   Whether the invite is temporary.
    #   @return [Boolean]

    @target_types = {
      nil => :voice,
      1 => :stream,
      2 => :guild,
    }.freeze

    # @!visibility private
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

    def url
      "https://discord.gg/#{@code}"
    end

    def remain_uses
      @max_uses && @max_uses - @uses
    end

    def temporary?
      @temporary
    end

    # Delete the invite.
    # @macro async
    # @macro http
    def delete!(reason: nil)
      Async do
        @client.http.delete("/invites/#{@code}", audit_log_reason: reason)
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
