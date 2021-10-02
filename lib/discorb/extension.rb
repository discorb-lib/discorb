# frozen_string_literal: true

module Discorb
  #
  # Module to make extension.
  # Extend this module to make your own extension.
  # @see file:docs/extension.md
  # @abstract
  #
  class Extension
    extend Discorb::ApplicationCommand::Handler

    @events = {}

    def initialize(client)
      @client = client
    end

    def events
      return @events if @events
      ret = {}
      self.class.events.each do |event, handlers|
        ret[event] = handlers.map do |handler|
          Discorb::Event.new(Proc.new { |*args, **kwargs| instance_exec(*args, **kwargs, &handler[2]) }, handler[0], handler[1])
        end
      end
      @events = ret
    end

    class << self
      undef setup_commands

      #
      # Define a new event.
      #
      # @param [Symbol] event_name The name of the event.
      # @param [Symbol] id The id of the event. Used to delete the event.
      # @param [Hash] metadata Other metadata.
      #
      # @return [Discorb::Event] The event.
      #
      def event(event_name, id: nil, **metadata, &block)
        raise ArgumentError, "Event name must be a symbol" unless event_name.is_a?(Symbol)
        raise ArgumentError, "block must be given" unless block_given?

        @events[event_name] ||= []
        metadata[:extension] = self.name
        @events[event_name] << [id, metadata, block]
      end

      #
      # Define a new once event.
      #
      # @param [Symbol] event_name The name of the event.
      # @param [Symbol] id The id of the event. Used to delete the event.
      # @param [Hash] metadata Other metadata.
      # @param [Proc] block The block to execute when the event is triggered.
      #
      # @return [Discorb::Event] The event.
      #
      def once_event(event_name, id: nil, **metadata, &block)
        event(event_name, id: id, once: true, **metadata, &block)
      end

      # @return [Hash{Symbol => Array<Discorb::Event>}] The events of the extension.
      attr_reader :events
      # @return [Array<Discorb::ApplicationCommand::Command>] The commands of the extension.
      attr_reader :commands
      # @private
      attr_reader :bottom_commands

      def inherited(klass)
        klass.instance_variable_set(:@commands, [])
        klass.instance_variable_set(:@bottom_commands, [])
        klass.instance_variable_set(:@events, {})
      end
    end
  end
end
