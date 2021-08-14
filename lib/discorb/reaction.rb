# frozen_string_literal: true

module Discorb
  class Reaction < DiscordModel
    attr_reader :count, :emoji, :message

    def initialize(message, data)
      @message = message
      _set_data(data)
    end

    def me?
      @me
    end
    alias reacted? me?

    def fetch_users(...)
      message.fetch_reacted_users(@emoji, ...)
    end

    private

    def _set_data(data)
      @count = data[:count]
      @me = data[:me]
      @emoji = if data[:emoji][:id].nil?
                 UnicodeEmoji.new(data[:emoji][:name])
               else
                 PartialEmoji.new(data[:emoji])
               end
    end
  end
end
