# frozen_string_literal: true

require "discorb"

RSpec.describe Discorb::Button do
  it "creates a select menu" do
    expect do
      Discorb::TextInput.new("text", "text", :short)
    end.not_to raise_error
  end

  it "converts to payload" do
    expect(Discorb::TextInput.new("text", "text", :short).to_hash).to eq(
      {
        custom_id: "text",
        label: "text",
        max_length: nil,
        min_length: nil,
        placeholder: nil,
        required: false,
        style: 1,
        type: 4,
        value: nil
      }
    )
  end
end
