# frozen_string_literal: true

require_relative "../common"

RSpec.describe Discorb::ChannelContainer do
  channel_classes = {
    text_channels: Discorb::TextChannel,
    voice_channels: Discorb::VoiceChannel,
    news_channels: Discorb::NewsChannel,
    stage_channels: Discorb::StageChannel,
  }
  let(:dummy) do
    Class.new do
      include Discorb::ChannelContainer

      define_method(:channels) do
        channel_classes.values.map do |channel_class|
          [channel_class.allocate] * 2
        end.flatten
      end
    end
  end

  specify "Discorb::Guild includes Discorb::ChannelContainer" do
    expect(Discorb::Guild.ancestors).to include(described_class)
  end

  specify "Discorb::CategoryChannel includes Discorb::ChannelContainer" do
    expect(Discorb::CategoryChannel.ancestors).to include(described_class)
  end

  channel_classes.each do |method, channel_class|
    specify "##{method} returns all #{channel_class}s" do
      channels = dummy.new.send(method)
      expect(channels).to all(be_a channel_class)
      expect(channels.length).to eq 2
    end
  end
end
