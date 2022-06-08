# frozen_string_literal: true

module Discorb
  #
  # Abstract class to make extension.
  # Include from this module to make your own extension.
  # @see file:docs/extension.md Extension
  # @abstract
  #
  module Extension
    def initialize(client)
      @client = client
    end

    def events
      return @events if @events

      ret = {}
      self.class.events.each do |event, handlers|
        ret[event] = handlers.map do |handler|
          Discorb::EventHandler.new(proc { |*args, **kwargs|
            instance_exec(*args, **kwargs, &handler[2])
          }, handler[0], handler[1])
        end
      end
      @events = ret
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    #
    # @private
    # Module for adding class methods to the extension class.
    #
    module ClassMethods
      include Discorb::ApplicationCommand::Handler
      undef setup_commands

      #
      # Define a new event.
      #
      # @param [Symbol] event_name The name of the event.
      # @param [Symbol] id The id of the event. Used to delete the event.
      # @param [Hash] metadata Other metadata.
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
      def once_event(event_name, id: nil, **metadata, &block)
        event(event_name, id: id, once: true, **metadata, &block)
      end

      # @return [Hash{Symbol => Array<Discorb::EventHandler>}] The events of the extension.
      attr_reader :events
      # @return [Array<Discorb::ApplicationCommand::Command>] The commands of the extension.
      attr_reader :commands
      # @private
      attr_reader :callable_commands

      def self.extended(klass)
        klass.instance_variable_set(:@commands, [])
        klass.instance_variable_set(:@callable_commands, [])
        klass.instance_variable_set(:@events, {})
      end
    end
  end
end
