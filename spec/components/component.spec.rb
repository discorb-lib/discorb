# frozen_string_literal: true
require "discorb"

RSpec.describe Discorb::Component do
  it "creates action row" do
    expect(Discorb::Component.to_payload(
      [Discorb::Button.new("label", :primary, custom_id: "id")]
    )).to eq(
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
end
