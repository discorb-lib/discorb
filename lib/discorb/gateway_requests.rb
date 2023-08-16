# frozen_string_literal: true

module Discorb
  #
  # Represents an activity for Gateway Command.
  #
  class Activity
    # @return [String] The text of the activity.
    attr_reader :text
    # @return [:playing, :streaming, :listening, :watching, :custom, :competing] The type of the activity.
    attr_reader :type
    # @return [String] The URL of the activity.
    attr_reader :url

    # @private
    # @return [{Symbol => Integer}] The mapping of activity types.
    TYPES = {
      playing: 0,
      streaming: 1,
      listening: 2,
      watching: 3,
      custom: 4,
      competing: 5
    }.freeze

    #
    # Initializes a new Activity.
    #
    # @param [String] text The text of the activity.
    # @param [:playing, :streaming, :listening, :watching, :custom, :competing] type The type of activity.
    # @param [String] url The URL of the activity.
    #
    def initialize(text, type = :playing, url: nil)
      @text = text
      @type =
        (
          if TYPES.key?(type)
            TYPES[type]
          else
            raise(ArgumentError, "invalid activity type: #{type}")
          end
        )
      @url = url
    end

    #
    # Converts the activity to a hash.
    #
    # @return [Hash] A hash representation of the activity.
    #
    def to_hash
      if @type == :custom
        { state: @text, type: @type, url: @url }
      else
        { name: @text, type: @type, url: @url }
      end
    end

    def inspect
      "#<#{self.class} @type=#{@type}>"
    end
  end
end
