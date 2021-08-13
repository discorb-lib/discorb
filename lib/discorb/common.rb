# frozen_string_literal: true

require_relative 'version'

module Discorb
  API_BASE_URL = 'https://discord.com/api/v9'
  USER_AGENT = "DiscordBot (https://github.com/discorb-lib/discorb #{VERSION}) Ruby/#{RUBY_VERSION}"

  class DiscordModel
    def ==(other)
      if respond_to?(:id) && other.respond_to?(:id)
        id == other.id
      else
        super
      end
    end

    def discorb?
      true
    end
  end

  class Snowflake < DiscordModel
    def initialize(value)
      @value = value.to_i
    end

    def to_s
      @value.to_s
    end

    def to_i
      @value.to_i
    end

    def ==(other)
      to_s == other.to_s
    end

    def timestamp
      Time.at(((sf >> 22) + 1_420_070_400_000) / 1000)
    end

    def worker_id
      (snowflake & 0x3E0000) >> 17
    end

    def process_id
      (snowflake & 0x1F000) >> 12
    end

    def increment
      snowflake & 0xFFF
    end
  end
end
