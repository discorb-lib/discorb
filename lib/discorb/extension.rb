# frozen_string_literal: true

module Discorb
  #
  # Module to make extension.
  # extend this module to make your own extension.
  # @see file:docs/extension.md
  # @abstract
  #
  module Extension
    @events = {}
    @client = nil

    #
    # Define a new event.
    #
    # @param [Symbol] event_name The name of the event.
    # @param [Symbol] id The id of the event. Used to delete the event.
    # @param [Hash] discriminator Other discriminators.
    # @param [Proc] block The block to execute when the event is triggered.
    #
    # @return [Discorb::Event] The event.
    #
    def event(event_name, id: nil, **discriminator, &block)
      raise ArgumentError, "Event name must be a symbol" unless event_name.is_a?(Symbol)
      raise ArgumentError, "block must be a Proc" unless block.is_a?(Proc)

      @events[event_name] ||= []
      discriminator[:extension] = self.name
      @events[event_name] << Discorb::Event.new(block, id, discriminator)
    end

    #
    # Define a new once event.
    #
    # @param [Symbol] event_name The name of the event.
    # @param [Symbol] id The id of the event. Used to delete the event.
    # @param [Hash] discriminator Other discriminators.
    # @param [Proc] block The block to execute when the event is triggered.
    #
    # @return [Discorb::Event] The event.
    #
    def once_event(event_name, id: nil, **discriminator, &block)
      event(event_name, id: id, once: true, **discriminator, &block)
    end

    # @return [Hash{Symbol => Array<Discorb::Event>}] The events of the extension.
    attr_reader :events

    # @!visibility private
    attr_accessor :client

    def self.extended(obj)
      obj.instance_variable_set(:@events, {})
    end
  end
end
