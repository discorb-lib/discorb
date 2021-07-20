# frozen_string_literal: true

require_relative 'common'
require_relative 'emoji'
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

    private

    def _set_data(data)
      @count = data[:count]
      @me = data[:me]
      @emoji = if data[:emoji][:id].nil?
                 UnicodeEmoji.new(data[:emoji][:name])
               else
                 PartialEmoji.new(data)
               end
    end
  end
end
