# frozen_string_literal: true

RSpec.describe Discorb::ChannelContainer do
  specify "Discorb::Guild includes Discorb::ChannelContainer" do
    expect(Discorb::Guild.ancestors).to include(described_class)
  end

  specify "Discorb::CategoryChannel includes Discorb::ChannelContainer" do
    expect(Discorb::CategoryChannel.ancestors).to include(described_class)
  end
end
