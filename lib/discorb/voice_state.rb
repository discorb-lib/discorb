# frozen_string_literal: true

module Discorb
  #
  # Represents a state of user in voice channel.
  #
  class VoiceState < DiscordModel
    # @return [Discorb::Member] The member associated with this voice state.
    attr_reader :member
    # @return [Discorb::Snowflake] The ID of the guild this voice state is for.
    attr_reader :session_id
    # @return [Time] The time at which the user requested to speak.
    attr_reader :request_to_speak_timestamp
    # @return [Boolean] Whether the user is deafened.
    attr_reader :self_deaf
    alias self_deaf? self_deaf
    # @return [Boolean] Whether the user is muted.
    attr_reader :self_mute
    alias self_mute? self_mute
    # @return [Boolean] Whether the user is streaming.
    attr_reader :self_stream
    alias stream? self_stream
    alias live? stream?
    # @return [Boolean] Whether the user is video-enabled.
    attr_reader :self_video
    alias video? self_video
    # @return [Boolean] Whether the user is suppressed. (Is at audience)
    attr_reader :suppress
    alias suppress? suppress

    # @!attribute [r] deaf?
    #   @return [Boolean] Whether the user is deafened.
    # @!attribute [r] mute?
    #   @return [Boolean] Whether the user is muted.
    # @!attribute [r] server_deaf?
    #   @return [Boolean] Whether the user is deafened on the server.
    # @!attribute [r] server_mute?
    #   @return [Boolean] Whether the user is muted on the server.
    # @!attribute [r] guild
    #   @macro client_cache
    #   @return [Discorb::Guild] The guild this voice state is for.
    # @!attribute [r] channel
    #   @macro client_cache
    #   @return [Discorb::Channel] The channel this voice state is for.
    # @!attribute [r] user
    #   @macro client_cache
    #   @return [Discorb::User] The user this voice state is for.

    #
    # Initialize a new voice state.
    # @private
    #
    # @param [Discorb::Client] client The client this voice state belongs to.
    # @param [Hash] data The data of the voice state.
    #
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

    def server_deaf?
      @deaf
    end

    def server_mute?
      @mute
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

  #
  # Represents a stage instance of a voice state.
  #
  class StageInstance < DiscordModel
    # @return [Discorb::Snowflake] The ID of the guild this voice state is for.
    attr_reader :id
    # @return [String] The topic of the stage instance.
    attr_reader :topic
    # @return [:public, :guild_only] The privacy level of the stage instance.
    attr_reader :privacy_level

    # @!attribute [r] guild
    #   @macro client_cache
    #   @return [Discorb::Guild] The guild this voice state is for.
    # @!attribute [r] channel
    #   @macro client_cache
    #   @return [Discorb::Channel] The channel this voice state is for.
    # @!attribute [r] discoverable?
    #   @return [Boolean] Whether the stage instance is discoverable.
    # @!attribute [r] public?
    #   @return [Boolean] Whether the stage instance is public.
    # @!attribute [r] guild_only?
    #   @return [Boolean] Whether the stage instance is guild-only.

    @privacy_level = {
      1 => :public,
      2 => :guild_only,
    }

    #
    # Initialize a new instance of the StageInstance class.
    # @private
    #
    # @param [Discorb::Client] client The client.
    # @param [Hash] data The data of the stage instance.
    # @param [Boolean] no_cache Whether to disable caching.
    #
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

    #
    # Edits the stage instance.
    # @async
    # @macro edit
    #
    # @param [String] topic The new topic of the stage instance.
    # @param [:public, :guild_only] privacy_level The new privacy level of the stage instance.
    # @param [String] reason The reason for editing the stage instance.
    #
    # @return [Async::Task<void>] The task.
    #
    def edit(topic: Discorb::Unset, privacy_level: Discorb::Unset, reason: nil)
      Async do
        payload = {}
        payload[:topic] = topic if topic != Discorb::Unset
        payload[:privacy_level] = PRIVACY_LEVEL.key(privacy_level) if privacy_level != Discorb::Unset
        @client.http.request(
          Route.new("/stage-instances/#{@channel_id}", "//stage-instances/:channel_id", :patch), payload, audit_log_reason: reason,
        ).wait
        self
      end
    end

    alias modify edit

    #
    # Deletes the stage instance.
    #
    # @param [String] reason The reason for deleting the stage instance.
    #
    # @return [Async::Task<void>] The task.
    #
    def delete!(reason: nil)
      Async do
        @client.http.request(Route.new("/stage-instances/#{@channel_id}", "//stage-instances/:stage_instance_id", :delete), audit_log_reason: reason).wait
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
      @privacy_level = PRIVACY_LEVEL[data[:privacy_level]]
      @discoverable_disabled = data[:discoverable_disabled]
    end

    class << self
      attr_reader :privacy_level
    end
  end

  #
  # Represents a voice region.
  #
  class VoiceRegion < DiscordModel
    # @return [Discorb::Snowflake] The ID of the voice region.
    attr_reader :id
    # @return [String] The name of the voice region.
    attr_reader :name
    # @return [Boolean] Whether the voice region is VIP.
    attr_reader :vip
    alias vip? vip
    # @return [Boolean] Whether the voice region is optimal.
    attr_reader :optimal
    alias optimal? optimal
    # @return [Boolean] Whether the voice region is deprecated.
    attr_reader :deprecated
    alias deprecated? deprecated
    # @return [Boolean] Whether the voice region is custom.
    attr_reader :custom
    alias custom? custom

    #
    # Initialize a new instance of the VoiceRegion class.
    # @private
    #
    # @param [Hash] data The data of the voice region.
    #
    def initialize(data)
      @id = data[:id]
      @name = data[:name]
      @vip = data[:vip]
      @optimal = data[:optimal]
      @deprecated = data[:deprecated]
      @custom = data[:custom]
    end
  end
end
