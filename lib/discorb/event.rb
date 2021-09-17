# frozen_string_literal: true

module Discorb
  #
  # Represents a event.
  # This class shouldn't be instantiated directly.
  # Use {Client#on} instead.
  #
  class Event
    # @return [Proc] the block to be called.
    attr_reader :block
    # @return [Symbol] the event id.
    attr_reader :id
    # @return [Hash] the event metadata.
    attr_reader :metadata
    # @return [Boolean] whether the event is once or not.
    attr_reader :once
    alias once? once

    def initialize(block, id, metadata)
      @block = block
      @id = id
      @once = metadata.fetch(:once, false)
      @metadata = metadata
      @rescue = nil
    end

    #
    # Calls the block associated with the event.
    #
    def call(...)
      @block.call(...)
    end
  end
end
