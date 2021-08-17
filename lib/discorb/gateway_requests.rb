# frozen_string_literal: true

module Discorb
  #
  # Represents an activity for Gateway Command.
  #
  class Activity
    @types = {
      playing: 0,
      streaming: 1,
      listening: 2,
      watching: 3,
      competing: 5
    }.freeze

    #
    # Initializes a new Activity.
    #
    # @param [String] name The name of the activity.
    # @param [:playing, :streaming, :listening, :watching, :competing] type The type of activity.
    # @param [String] url The URL of the activity.
    #
    def initialize(name, type = :playing, url = nil)
      @name = name
      @type = self.class.types[type]
      @url = url
    end

    #
    # Converts the activity to a hash.
    #
    # @return [Hash] A hash representation of the activity.
    #
    def to_hash
      {
        name: @name,
        type: @type,
        url: @url
      }
    end

    class << self
      # @!visibility private
      attr_reader :types
    end
  end
end
