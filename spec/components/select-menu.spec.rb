# frozen_string_literal: true
require "discorb"

RSpec.describe Discorb::Button do
  it "creates a select menu" do
    expect do
      Discorb::SelectMenu.new("menu", [
        Discorb::SelectMenu::Option.new("label", "value")
      ])
    end.not_to raise_error
  end
  it "converts to payload" do
    expect(Discorb::SelectMenu.new("menu", [
      Discorb::SelectMenu::Option.new("label", "value")
    ]).to_hash).to eq(
      {
        custom_id: "menu",
        disabled: nil,
        max_values: 1,
        min_values: 1,
        options: [{ default: false, description: nil, emoji: nil, label: "label", value: "value" }],
        placeholder: nil,
        type: 3,
      }
    )
  end
end
