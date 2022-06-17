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
    PRESET_TYPES = {
      1 => :profanity,
      2 => :sexual_content,
      3 => :slurs,
    }.freeze
    EVENT_TYPES = {
      1 => :message_send,
    }.freeze

    # @return [Discorb::Snowflake] The ID of the rule.
    attr_reader :id
    # @return [String] The name of the rule.
    attr_reader :name
    # @return [Boolean] Whether the rule is enabled.
    attr_reader :enabled
    alias enabled? enabled
    # @return [Array<Discorb::AutoModRule::Action>] The actions of the rule.
    attr_reader :actions
    # @return [Array<String>] The keywords that the rule is triggered by.
    # @note This is only available if the trigger type is `:keyword`.
    attr_reader :keyword_filter

    #
    # Initialize a new auto mod.
    # @private
    #
    # @param [Discorb::Client] client The client.
    # @param [Hash] data The auto mod data.
    #
    def initialize(client, data)
      @client = client
      _set_data(data)
    end

    # @!attribute [r]
    #   @return [Symbol] Returns the type of the preset.
    #   @note This is only available if the trigger type is `:keyword_preset`.
    def preset_type
      PRESET_TYPES[@presets_raw]
    end

    # @!attribute [r]
    #   @return [Symbol] Returns the type of the trigger.
    def trigger_type
      TRIGGER_TYPES[@trigger_type_raw]
    end

    # @!attribute [r]
    #   @return [Symbol] Returns the type of the event.
    def event_type
      EVENT_TYPES[@event_type_raw]
    end

    # @!attribute [r]
    #   @macro client_cache
    #   @return [Discorb::Member] The member who created the rule.
    def creator
      guild.members[@creator_id]
    end

    # @!attribute [r]
    #   @return [Discorb::Guild] The guild that the rule is in.
    def guild
      @client.guilds[@guild_id]
    end

    # @!attribute [r]
    #   @return [Array<Discorb::Role>] The roles that the rule is exempt from.
    def exempt_roles
      @exempt_roles_id.map { |id| guild.roles[id] }
    end

    # @!attribute [r]
    #   @return [Array<Discorb::Channel>] The channels that the rule is exempt from.
    def exempt_channels
      @exempt_channels_id.map { |id| guild.channels[id] }
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
      ACTION_TYPES = {
        1 => :block_message,
        2 => :send_alert_message,
        3 => :timeout,
      }.freeze

      # @return [Symbol] Returns the type of the action.
      attr_reader :type
      # @return [Integer] The duration of the timeout.
      # @note This is only available if the action type is `:timeout`.
      attr_reader :duration_seconds

      #
      # Initialize a new action.
      # @private
      #
      # @param [Discorb::Client] client The client.
      # @param [Hash] data The action data.
      #
      def initialize(client, data)
        @client = client
        _set_data(data)
      end

      # @!attribute [r]
      #   @return [Discorb::Channel] The channel that the action is sent to.
      def channel
        @client.channels[@channel_id]
      end

      # @private
      def _set_data(data)
        @type = ACTION_TYPES[data[:type]]
        @channel_id = data[:metadata][:channel_id]
        @duration_seconds = data[:metadata][:duration_seconds]
      end
    end
  end
end
