# frozen_string_literal: true

module Discorb
  #
  # Represents a rule of auto moderation.
  #
  class AutoModRule < DiscordModel
    # @return [Hash{Integer => Symbol}] The mapping of trigger types.
    # @private
    TRIGGER_TYPES = {
      1 => :keyword,
      2 => :harmful_link,
      3 => :spam,
      4 => :keyword_preset,
    }.freeze
    # @return [Hash{Integer => Symbol}] The mapping of preset types.
    # @private
    PRESET_TYPES = {
      1 => :profanity,
      2 => :sexual_content,
      3 => :slurs,
    }.freeze
    # @return [Hash{Integer => Symbol}] The mapping of event types.
    # @private
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

    #
    # Edit the rule.
    # @async
    # @edit
    #
    # @param [String] name The name of the rule.
    # @param [Symbol] event_type The event type of the rule. See {Discorb::AutoModRule::EVENT_TYPES}.
    # @param [Array<Discorb::AutoModRule::Action>] actions The actions of the rule.
    # @param [Boolean] enabled Whether the rule is enabled or not.
    # @param [Array<Discorb::Role>] exempt_roles The roles that are exempt from the rule.
    # @param [Array<Discorb::Channel>] exempt_channels The channels that are exempt from the rule.
    # @param [Array<String>] keyword_filter The keywords to filter.
    # @param [Symbol] presets The preset of the rule. See {Discorb::AutoModRule::PRESET_TYPES}.
    # @param [String] reason The reason for creating the rule.
    #
    # @return [Async::Task<void>] The task.
    #
    def edit(
      name: Discorb::Unset,
      event_type: Discorb::Unset,
      actions: Discorb::Unset,
      enabled: Discorb::Unset,
      exempt_roles: Discorb::Unset,
      exempt_channels: Discorb::Unset,
      keyword_filter: Discorb::Unset,
      presets: Discorb::Unset,
      reason: nil
    )
      # @type var payload: Hash[Symbol, untyped]
      payload = {
        metadata: {},
      }
      payload[:name] = name unless name == Discorb::Unset
      payload[:event_type] = EVENT_TYPES.key(event_type) unless event_type == Discorb::Unset
      payload[:actions] = actions unless actions == Discorb::Unset
      payload[:enabled] = enabled unless enabled == Discorb::Unset
      payload[:exempt_roles] = exempt_roles.map(&:id) unless exempt_roles == Discorb::Unset
      payload[:exempt_channels] = exempt_channels.map(&:id) unless exempt_channels == Discorb::Unset
      payload[:metadata][:keyword_filter] = keyword_filter unless keyword_filter == Discorb::Unset
      payload[:metadata][:presets] = PRESET_TYPES.key(presets) unless presets == Discorb::Unset

      @client.http.request(
        Route.new(
          "/guilds/#{@guild_id}/automod/rules/#{@id}",
          "//guilds/:guild_id/automod/rules/:id",
          :patch
        ),
        payload,
        audit_log_reason: reason,
      )
    end

    #
    # Delete the rule.
    #
    # @param [String] reason The reason for deleting the rule.
    #
    # @return [Async::Task<void>] The task.
    #
    def delete(reason: nil)
      Async do
        @client.http.request(
          Route.new(
            "/guilds/#{@guild_id}/automod/rules/#{@id}",
            "//guilds/:guild_id/automod/rules/:id",
            :delete
          ),
          audit_log_reason: reason,
        )
      end
    end

    # @private
    def _set_data(data)
      @id = Snowflake.new(data[:id])
      @guild_id = data[:guild_id]
      @name = data[:name]
      @creator_id = data[:creator_id]
      @trigger_type_raw = data[:trigger_type]
      @event_type_raw = data[:event_type]
      @actions = data[:actions].map { |action| Action.from_hash(@client, action) }
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
      # @return [Hash{Integer => Symbol}] The mapping of action types.
      # @private
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
      #
      # @param [Symbol] type The type of the action.
      # @param [Integer] duration_seconds The duration of the timeout.
      #   This is only available if the action type is `:timeout`.
      # @param [Discorb::Channel] channel The channel that the alert message is sent to.
      #   This is only available if the action type is `:send_alert_message`.
      #
      def initialize(type, duration_seconds: nil, channel: nil)
        @type = type
        @duration_seconds = duration_seconds
        @channel = channel
      end

      #
      # Convert the action to hash.
      #
      # @return [Hash] The action hash.
      #
      def to_hash
        {
          type: @type,
          metadata: {
            channel_id: @channel&.id,
            duration_seconds: @duration_seconds,
          },
        }
      end

      #
      # Initialize a new action from hash.
      # @private
      #
      # @param [Discorb::Client] client The client.
      # @param [Hash] data The action data.
      #
      def initialize_hash(client, data)
        @client = client
        _set_data(data)
      end

      # @!attribute [r]
      #   @return [Discorb::Channel] The channel that the alert message is sent to.
      #   @note This is only available if the action type is `:send_alert_message`.
      def channel
        @client.channels[@channel_id]
      end

      # @private
      def _set_data(data)
        @type = ACTION_TYPES[data[:type]]
        @channel_id = data[:metadata][:channel_id]
        @duration_seconds = data[:metadata][:duration_seconds]
      end

      def self.from_hash(client, data)
        allocate.tap { |action| action.initialize_hash(client, data) }
      end
    end
  end
end
