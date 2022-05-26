# frozen_string_literal: true

module Discorb
  #
  # Represents a reaction to a message.
  #
  class Reaction < DiscordModel
    # @return [Integer] The number of users that have reacted with this emoji.
    attr_reader :count
    # @return [Discorb::Emoji] The emoji that was reacted with.
    attr_reader :emoji
    # @return [Discorb::Message] The message that this reaction is on.
    attr_reader :message
    # @return [Boolean] Whether client user reacted with this emoji.
    attr_reader :me
    alias me? me
    alias reacted? me

    #
    # Initialize a new reaction.
    # @private
    #
    # @param [Discorb::Message] message The message that this reaction is on.
    # @param [Hash] data The data of the reaction.
    #
    def initialize(message, data)
      @message = message
      _set_data(data)
    end

    #
    # Fetch the user that reacted with this emoji.
    #
    # @param (see Message#fetch_reacted_users)
    #
    # @return [Array<Discorb::User>] The users that reacted with this emoji.
    #
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
