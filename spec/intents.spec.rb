# frozen_string_literal: true
require "rspec"

RSpec.describe Discorb::Intents do
  Discorb::Intents::INTENT_BITS.each do |key, value|
    specify "##{key} is associated with #{value}" do
      expect(Discorb::Intents.from_value(value)).to(satisfy { |intent| intent.send(key) })
    end
    specify "value of .new with `#{key}: true` is #{value}" do
      intent = Discorb::Intents.none
      intent.send("#{key}=", true)
      expect(intent.value).to eq(value)
    end
  end
end
