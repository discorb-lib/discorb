# frozen_string_literal: true

module Discorb
  # @return [String] The API base URL.
  API_BASE_URL = "https://discord.com/api/v9"
  # @return [String] The version of discorb.
  VERSION = "0.11.2"
  # @return [String] The user agent for the bot.
  USER_AGENT = "DiscordBot (https://discorb-lib.github.io #{VERSION}) Ruby/#{RUBY_VERSION}"

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

    # @private
    def inspect
      super
    end

    def hash
      @id.hash
    end
  end

  #
  # Represents Snowflake of Discord.
  #
  # @see https://discord.com/developers/docs/reference#snowflakes Official Discord API docs
  class Snowflake < String
    # @private
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
      Time.at(((@value >> 22) + 1_420_070_400_000) / 1000)
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

    alias id to_s
  end
end
