# frozen_string_literal: true

module Discorb
  class Event
    attr_reader :block, :id, :discriminator

    def initialize(block, id, discriminator)
      @block = block
      @id = id
      @discriminator = discriminator
      @rescue = nil
    end

    def call(...)
      @block.call(...)
    end

    def rescue(&block)
      if block_given?
        @rescue = block
      else
        @rescue
      end
    end
  end
end
