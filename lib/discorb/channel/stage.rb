# frozen_string_literal: true

module Discorb
  #
  # Represents a stage channel.
  #
  class StageChannel < GuildChannel
    # @return [Integer] The bitrate of the voice channel.
    attr_reader :bitrate
    # @return [Integer] The user limit of the voice channel.
    attr_reader :user_limit
    #
    # @private
    # @return [Discorb::Dictionary{Discorb::Snowflake => StageInstance}]
    #   The stage instances associated with the stage channel.
    #
    attr_reader :stage_instances

    include Connectable

    # @!attribute [r] stage_instance
    #   @return [Discorb::StageInstance] The stage instance of the channel.

    @channel_type = 13
    #
    # Initialize a new stage channel.
    # @private
    #
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
    def edit(
      name: Discorb::Unset,
      position: Discorb::Unset,
      bitrate: Discorb::Unset,
      rtc_region: Discorb::Unset,
      reason: nil
    )
      Async do
        payload = {}
        payload[:name] = name if name != Discorb::Unset
        payload[:position] = position if position != Discorb::Unset
        payload[:bitrate] = bitrate if bitrate != Discorb::Unset
        payload[:rtc_region] = rtc_region if rtc_region != Discorb::Unset
        @client
          .http
          .request(
            Route.new("/channels/#{@id}", "//channels/:channel_id", :patch),
            payload,
            audit_log_reason: reason
          )
          .wait
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
        _resp, data =
          @client
            .http
            .request(
              Route.new("/stage-instances", "//stage-instances", :post),
              { channel_id: @id, topic:, public: public ? 2 : 1 },
              audit_log_reason: reason
            )
            .wait
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
        _resp, data =
          @client
            .http
            .request(
              Route.new(
                "/stage-instances/#{@id}",
                "//stage-instances/:stage_instance_id",
                :get
              )
            )
            .wait
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
      voice_states.reject(&:suppress?).map(&:member)
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
end
