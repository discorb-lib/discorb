# frozen_string_literal: true

require_relative "common"

RSpec.describe Discorb::UnicodeEmoji do
  it "parses emoji" do
    parsed = described_class.new("\u{1f600}") # :grinning:
    expect(parsed.name).to eq("grinning")
    expect(parsed.value).to eq("\u{1f600}")
  end

  it "returns emoji from name" do
    emoji = described_class.new("grinning")
    expect(emoji.name).to eq("grinning")
    expect(emoji.value).to eq("\u{1f600}")
  end

  it "raises error" do
    expect { described_class.new("unknown_emoji") }.to raise_error(
      ArgumentError
    )
  end

  %w[🖐🏻 🖐🏼 🖐🏽 🖐🏾 🖐🏿].each.with_index do |emoji, i|
    it "parses emoji #{emoji} that has skin tone" do
      parsed = described_class.new(emoji)
      expect(parsed.name).to eq("hand_splayed_tone#{i + 1}")
    end

    it "returns #{emoji} from name and skin tone" do
      emoji = described_class.new("hand_splayed", tone: i + 1)
      expect(emoji.name).to eq("hand_splayed_tone#{i + 1}")
    end
  end

  it "raises error because the emoji doesn't support skin tone" do
    expect { described_class.new("grinning", tone: 1) }.to raise_error(
      ArgumentError
    )
  end
end
