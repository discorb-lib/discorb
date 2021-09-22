# frozen_string_literal: true

module Discorb
  # Represents intents.
  class Intents
    @intent_bits = {
      guilds: 1 << 0,
      members: 1 << 1,
      bans: 1 << 2,
      emojis: 1 << 3,
      integrations: 1 << 4,
      webhooks: 1 << 5,
      invites: 1 << 6,
      voice_states: 1 << 7,
      presences: 1 << 8,
      messages: 1 << 9,
      reactions: 1 << 10,
      typing: 1 << 11,
      dm_messages: 1 << 12,
      dm_reactions: 1 << 13,
      dm_typing: 1 << 14,
    }.freeze

    #
    # Create new intents object with default (no members and presence) intents.
    #
    # @param guilds [Boolean] Whether guild related events are enabled.
    # @param members [Boolean] Whether guild members related events are enabled.
    # @param bans [Boolean] Whether guild ban related events are enabled.
    # @param emojis [Boolean] Whether guild emojis related events are enabled.
    # @param integrations [Boolean] Whether guild integration related events are enabled.
    # @param webhooks [Boolean] Whether guild webhooks related events are enabled.
    # @param invites [Boolean] Whether guild invite related events are enabled.
    # @param voice_states [Boolean] Whether guild voice state related events are enabled.
    # @param presences [Boolean] Whether guild presences related events are enabled.
    # @param messages [Boolean] Whether guild messages related events are enabled.
    # @param reactions [Boolean] Whether guild reaction related events are enabled.
    # @param dm_messages [Boolean] Whether dm messages related events are enabled.
    # @param dm_reactions [Boolean] Whether dm reactions related events are enabled.
    # @param dm_typing [Boolean] Whether dm typing related events are enabled.
    #
    # @note You must enable privileged intents to use `members` and/or `presences` intents.
    #
    def initialize(guilds: true,
                   members: false,
                   bans: true,
                   emojis: true,
                   integrations: true,
                   webhooks: true,
                   invites: true,
                   voice_states: true,
                   presences: false,
                   messages: true,
                   reactions: true,
                   typing: true,
                   dm_messages: true,
                   dm_reactions: true,
                   dm_typing: true)
      @raw_value = {
        guilds: guilds,
        members: members,
        bans: bans,
        emojis: emojis,
        integrations: integrations,
        webhooks: webhooks,
        invites: invites,
        voice_states: voice_states,
        presences: presences,
        messages: messages,
        reactions: reactions,
        typing: typing,
        dm_messages: dm_messages,
        dm_reactions: dm_reactions,
        dm_typing: dm_typing,
      }
    end

    #
    # (see Flag#method_missing)
    #
    def method_missing(name, args = nil)
      if @raw_value.key?(name)
        @raw_value[name]
      elsif name.end_with?("=") && @raw_value.key?(name[0..-2].to_sym)
        raise ArgumentError, "true/false expected" unless args.is_a? TrueClass or args.is_a?(FalseClass)

        @raw_value[name[0..-2].to_sym] = args
      else
        super
      end
    end

    def respond_to_missing?(sym, include_private)
      @raw_value.key?(name) ? true : super
    end

    # Returns value of the intent.
    # @return [Integer] The value of the intent.
    def value
      res = 0
      self.class.intent_bits.each do |intent, bit|
        res += bit if @raw_value[intent]
      end
      res
    end

    def inspect
      "#<#{self.class} value=#{value}>"
    end

    def to_h
      @raw_value
    end

    class << self
      # Create new intent object from raw value.
      # @param value [Integer] The value of the intent.
      def from_value(value)
        raw_value = {}
        @intent_bits.each do |intent, bit|
          raw_value[intent] = value & bit != 0
        end
        new(**raw_value)
      end

      # Create new intent object with default values.
      def default
        from_value(32509)
      end

      # Create new intent object with all intents.
      def all
        from_value(32767)
      end

      # Create new intent object with no intents.
      def none
        from_value(0)
      end

      attr_reader :intent_bits
    end
  end
end
