# frozen_string_literal: true

module Discorb
  #
  # Represents a voice channel.
  #
  class VoiceChannel < GuildChannel
    # @return [Numeric] The bitrate of the voice channel.
    attr_reader :bitrate
    # @return [Numeric] The user limit of the voice channel.
    # @return [nil] If the user limit is not set.
    attr_reader :user_limit

    # @!attribute [r] members
    #   @return [Array<Discorb::Member>] The members in the voice channel.
    # @!attribute [r] voice_states
    #   @return [Array<Discorb::VoiceState>] The voice states associated with the voice channel.

    include Connectable
    include Messageable

    @channel_type = 2
    #
    # Edit the voice channel.
    # @async
    # @macro edit
    #
    # @param [String] name The name of the voice channel.
    # @param [Numeric] position The position of the voice channel.
    # @param [Numeric] bitrate The bitrate of the voice channel.
    # @param [Numeric] user_limit The user limit of the voice channel.
    # @param [Symbol] rtc_region The region of the voice channel.
    # @param [String] reason The reason of editing the voice channel.
    #
    # @return [Async::Task<self>] The edited voice channel.
    #
    def edit(
      name: Discorb::Unset,
      position: Discorb::Unset,
      bitrate: Discorb::Unset,
      user_limit: Discorb::Unset,
      rtc_region: Discorb::Unset,
      reason: nil
    )
      Async do
        payload = {}
        payload[:name] = name if name != Discorb::Unset
        payload[:position] = position if position != Discorb::Unset
        payload[:bitrate] = bitrate if bitrate != Discorb::Unset
        payload[:user_limit] = user_limit if user_limit != Discorb::Unset
        payload[:rtc_region] = rtc_region if rtc_region != Discorb::Unset

        @client.http.request(Route.new("/channels/#{@id}", "//channels/:channel_id", :patch), payload,
                             audit_log_reason: reason).wait
        self
      end
    end

    alias modify edit

    def voice_states
      guild.voice_states.select { |state| state.channel&.id == @id }
    end

    def members
      voice_states.map(&:member)
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
end
