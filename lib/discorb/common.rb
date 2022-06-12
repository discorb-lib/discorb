# frozen_string_literal: true

module Discorb
  # @return [String] The API base URL.
  API_BASE_URL = "https://discord.com/api/v10"
  # @return [String] The version of discorb.
  VERSION = "0.17.1"
  # @return [Array<Integer>] The version array of discorb.
  VERSION_ARRAY = VERSION.split(".").map(&:to_i).freeze
  # @return [String] The user agent for the bot.
  USER_AGENT = "DiscordBot (https://discorb-lib.github.io #{VERSION}) Ruby/#{RUBY_VERSION}".freeze

  #
  # @abstract
  # Represents Discord model.
  #
  class DiscordModel
    def eql?(other)
      self == other
    end

    def ==(other)
      if respond_to?(:id) && other.respond_to?(:id)
        id == other.id
      else
        super
      end
    end

    def inspect
      "#<#{self.class}: #{@id}>"
    end

    # @private
    def hash
      @id.hash
    end
  end

  #
  # Represents Snowflake of Discord.
  #
  # @see https://discord.com/developers/docs/reference#snowflakes Official Discord API docs
  class Snowflake < String
    #
    # Initialize new snowflake.
    # @private
    #
    # @param [#to_s] value The value of the snowflake.
    #
    def initialize(value)
      @value = value.to_i
      super(@value.to_s)
    end

    # @!attribute [r] timestamp
    #   Timestamp of snowflake.
    #
    #   @return [Time] Timestamp of snowflake.
    #
    # @!attribute [r] worker_id
    #   Worker ID of snowflake.
    #
    #   @return [Integer] Worker ID of snowflake.
    #
    # @!attribute [r] process_id
    #   Process ID of snowflake.
    #
    #   @return [Integer] Process ID of snowflake.
    # @!attribute [r] increment
    #   Increment of snowflake.
    #
    #   @return [Integer] Increment of snowflake.
    # @!attribute [r] id
    #   Alias of to_s.
    #
    #   @return [String] The snowflake.

    #
    # Compares snowflake with other object.
    #
    # @param [#to_s] other Object to compare with.
    #
    # @return [Boolean] True if snowflake is equal to other object.
    #
    def ==(other)
      return false unless other.respond_to?(:to_s)

      to_s == other.to_s
    end

    #
    # Alias of {#==}.
    #
    def eql?(other)
      self == other
    end

    # Return hash of snowflake.
    def hash
      to_s.hash
    end

    def timestamp
      Time.at(((@value >> 22) + 1_420_070_400_000) / 1000.0)
    end

    def worker_id
      (@value & 0x3E0000) >> 17
    end

    def process_id
      (@value & 0x1F000) >> 12
    end

    def increment
      @value & 0xFFF
    end

    def inspect
      "#<#{self.class} #{self}>"
    end

    alias id to_s
  end

  #
  # Represents an endpoint.
  # @private
  #
  class Route
    attr_reader :url, :key, :method

    def initialize(url, key, method)
      @url = url
      @key = key
      @method = method
    end

    def inspect
      "#<#{self.class} #{self.identifier}>"
    end

    def hash
      @url.hash
    end

    def identifier
      "#{@method} #{@key}"
    end

    def major_param
      param_type = @key.split("/").find { |k| k.start_with?(":") }
      return "" unless param_type

      param = url.gsub(API_BASE_URL, "").split("/")[@key.split("/").index(param_type) - 1]
      %w[:channel_id :guild_id :webhook_id].include?(param_type) ? param : ""
    end
  end

  # @return [Object] Object that represents unspecified value.
  #   This is used as a default value for optional parameters.
  Unset = Object.new
end
