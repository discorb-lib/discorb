# frozen_string_literal: true
require "discorb"

RSpec.describe Discorb::Button do
  context "Action buttons" do
    it "creates a button" do
      expect { Discorb::Button.new("label", :primary, custom_id: "id") }.not_to raise_error
    end
    it "converts to payload" do
      expect(Discorb::Button.new("label", :primary, custom_id: "id").to_hash).to eq(
        {
          type: 2,
          label: "label",
          style: 1,
          emoji: nil,
          custom_id: "id",
          disabled: false,
        }
      )
    end
  end
  context "Link buttons" do
    it "creates a button" do
      expect { Discorb::Button.new("label", :link, url: "https://discorb-lib.github.io") }.not_to raise_error
    end
    it "converts to payload" do
      expect(Discorb::Button.new("label", :link, url: "https://discorb-lib.github.io").to_hash).to eq(
        {
          type: 2,
          label: "label",
          style: 5,
          emoji: nil,
          url: "https://discorb-lib.github.io",
          disabled: false,
        }
      )
    end
  end
end
