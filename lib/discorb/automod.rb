# frozen_string_literal: true

module Discorb
  #
  # Represents a rule of auto moderation.
  #
  class AutoModRule < DiscordModel
    TRIGGER_TYPES = {
      1 => :keyword,
      2 => :harmful_link,
      3 => :spam,
      4 => :keyword_preset,
    }.freeze
    KEYWORD_FILTERS = {
      1 => :profanity,
      2 => :sexual_content,
      3 => :slurs,
    }.freeze
    EVENT_TYPES = {
      1 => :message_send,
    }.freeze

    #
    # Initialize a new auto mod.
    #
    # @param [<Type>] client <description>
    # @param [<Type>] data <description>
    #
    def initialize(client, data)
      @client = client
      _set_data(data)
    end

    # @private
    def _set_data(data)
      @id = Snowflake.new(data[:id])
      @guild_id = data[:guild_id]
      @name = data[:name]
      @creator_id = data[:creator_id]
      @trigger_type_raw = data[:trigger_type]
      @event_type_raw = data[:event_type]
      @actions = data[:actions].map { |action| Action.new(@client, action) }
      case trigger_type
      when :keyword
        @keyword_filter = data[:trigger_metadata][:keyword_filter]
      when :presets
        @presets_raw = data[:trigger_metadata][:presets]
      end
      @enabled = data[:enabled]
      @exempt_roles_id = data[:exempt_roles]
      @exempt_channels_id = data[:exempt_channels]
    end

    #
    # Represents the action of auto moderation.
    #
    class Action < DiscordModel
    end
  end
end
