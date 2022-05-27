# frozen_string_literal: true

require "discorb"

RSpec.describe Discorb::Component do
  let(:button) { Discorb::Button.new("label", :primary, custom_id: "id") }
  let(:select_menu) { Discorb::SelectMenu.new("id", []) }

  describe ".to_payload" do
    it "creates action row by button" do
      expect(described_class.to_payload([button])).to eq(
        [
          {
            components: [
              {
                custom_id: "id",
                disabled: false,
                emoji: nil,
                label: "label",
                style: 1,
                type: 2,
              },
            ],
            type: 1,
          },
        ]
      )
    end

    it "creates action row by 2D array" do
      expect(described_class.to_payload([[button], [button]])).to eq(
        [
          {
            components: [
              {
                custom_id: "id",
                disabled: false,
                emoji: nil,
                label: "label",
                style: 1,
                type: 2,
              },
            ],
            type: 1,
          },
          {
            components: [
              {
                custom_id: "id",
                disabled: false,
                emoji: nil,
                label: "label",
                style: 1,
                type: 2,
              },
            ],
            type: 1,
          },
        ]
      )
    end

    it "creates action row by single select menu" do
      expect(described_class.to_payload([select_menu])).to eq(
        [
          {
            components: [
              {
                custom_id: "id",
                disabled: nil,
                max_values: 1,
                min_values: 1,
                options: [],
                placeholder: nil,
                type: 3,
              },
            ],
            type: 1,
          },
        ]
      )
    end

    it "creates action row by select menu in buttons" do
      expect(described_class.to_payload([button, select_menu, button])).to eq(
        [
          {
            components: [
              {
                custom_id: "id",
                disabled: false,
                emoji: nil,
                label: "label",
                style: 1,
                type: 2,
              },
            ],
            type: 1,
          },
          {
            components: [
              {
                custom_id: "id",
                disabled: nil,
                max_values: 1,
                min_values: 1,
                options: [],
                placeholder: nil,
                type: 3,
              },
            ],
            type: 1,
          },
          {
            components: [
              {
                custom_id: "id",
                disabled: false,
                emoji: nil,
                label: "label",
                style: 1,
                type: 2,
              },
            ],
            type: 1,
          },
        ]
      )
    end
  end
end
