# frozen_string_literal: true

require "objspace"
require_relative "common"

ObjectSpace
  .each_object(Class)
  .filter { |c| c < Discorb::Flag }
  .each do |klass|
    RSpec.describe klass do
      klass.bits.each do |key, index|
        specify "##{key} is associated with 1 << #{index}" do
          expect(klass.new(1 << index).send(key)).to be true
        end
      end
    end
  end
