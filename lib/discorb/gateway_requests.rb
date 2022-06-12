# frozen_string_literal: true

module Discorb
  #
  # Represents an activity for Gateway Command.
  #
  class Activity
    # @private
    # @return [{Symbol => Numeric}] The mapping of activity types.
    TYPES = {
      playing: 0,
      streaming: 1,
      listening: 2,
      watching: 3,
      competing: 5,
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
      @type = TYPES[type] or raise ArgumentError, "Invalid activity type: #{type}"
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
        url: @url,
      }
    end

    def inspect
      "#<#{self.class} @type=#{@type}>"
    end
  end
end
