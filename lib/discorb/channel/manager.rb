module Discorb
  #
  # Manages channels.
  #
  module ChannelManager
    #
    # Returns text channels.
    #
    # @return [Array<Discorb::TextChannel>] The text channels.
    #
    def text_channels
      channels.filter { |c| c.is_a? TextChannel }
    end

    #
    # Returns voice channels.
    #
    # @return [Array<Discorb::VoiceChannel>] The voice channels.
    #
    def voice_channels
      channels.filter { |c| c.is_a? VoiceChannel }
    end

    #
    # Returns news channels.
    #
    # @return [Array<Discorb::NewsChannel>] The news channels.
    #
    def news_channels
      channels.filter { |c| c.is_a? NewsChannel }
    end

    #
    # Returns stage channels.
    #
    # @return [Array<Discorb::StageChannel>] The stage channels.
    #
    def stage_channels
      channels.filter { |c| c.is_a? StageChannel }
    end
  end
end
