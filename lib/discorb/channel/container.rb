# frozen_string_literal: true

module Discorb
  #
  # Module for container of channels.
  #
  module ChannelContainer
    #
    # Returns text channels.
    #
    # @return [Array<Discorb::TextChannel>] The text channels.
    #
    def text_channels
      channels.filter { |c| c.instance_of? TextChannel }
    end

    #
    # Returns voice channels.
    #
    # @return [Array<Discorb::VoiceChannel>] The voice channels.
    #
    def voice_channels
      channels.filter { |c| c.instance_of? VoiceChannel }
    end

    #
    # Returns news channels.
    #
    # @return [Array<Discorb::NewsChannel>] The news channels.
    #
    def news_channels
      channels.filter { |c| c.instance_of? NewsChannel }
    end

    #
    # Returns stage channels.
    #
    # @return [Array<Discorb::StageChannel>] The stage channels.
    #
    def stage_channels
      channels.filter { |c| c.instance_of? StageChannel }
    end
  end
end
