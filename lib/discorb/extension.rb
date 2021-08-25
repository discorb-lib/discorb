# frozen_string_literal: true

module Discorb
  module Extension
    @events = {}
    @client = nil

    def event(event_name, id: nil, **discriminator, &block)
      @events = {} if @events.nil?
      @events[event_name] = [] if @events[event_name].nil?
      discriminator[:extension] = Extension
      @events[event_name] << Discorb::Event.new(block, id, discriminator)
    end

    attr_reader :events
    attr_accessor :client
  end
end
