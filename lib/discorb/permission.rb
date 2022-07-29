# frozen_string_literal: true

module Discorb
  #
  # Represents a permission per guild.
  # ## Flag fields
  #
  # | Field | Value |
  # |-------|-------|
  # |`1 << 0`|`:create_instant_invite`|
  # |`1 << 1`|`:kick_members`|
  # |`1 << 2`|`:ban_members`|
  # |`1 << 3`|`:administrator`|
  # |`1 << 4`|`:manage_channels`|
  # |`1 << 5`|`:manage_guild`|
  # |`1 << 6`|`:add_reactions`|
  # |`1 << 7`|`:view_audit_log`|
  # |`1 << 8`|`:priority_speaker`|
  # |`1 << 9`|`:stream`|
  # |`1 << 10`|`:view_channel`|
  # |`1 << 11`|`:send_messages`|
  # |`1 << 12`|`:send_tts_messages`|
  # |`1 << 13`|`:manage_messages`|
  # |`1 << 14`|`:embed_links`|
  # |`1 << 15`|`:attach_files`|
  # |`1 << 16`|`:read_message_history`|
  # |`1 << 17`|`:mention_everyone`|
  # |`1 << 18`|`:use_external_emojis`|
  # |`1 << 19`|`:view_guild_insights`|
  # |`1 << 20`|`:connect`|
  # |`1 << 21`|`:speak`|
  # |`1 << 22`|`:mute_members`|
  # |`1 << 23`|`:deafen_members`|
  # |`1 << 24`|`:move_members`|
  # |`1 << 25`|`:use_vad`|
  # |`1 << 26`|`:change_nickname`|
  # |`1 << 27`|`:manage_nicknames`|
  # |`1 << 28`|`:manage_roles`|
  # |`1 << 29`|`:manage_webhooks`|
  # |`1 << 30`|`:manage_emojis`|
  # |`1 << 31`|`:use_slash_commands`|
  # |`1 << 32`|`:request_to_speak`|
  # |`1 << 34`|`:manage_threads`|
  # |`1 << 35`|`:use_public_threads`|
  # |`1 << 36`|`:use_private_threads`|
  #
  class Permission < Flag
    @bits = {
      create_instant_invite: 0,
      kick_members: 1,
      ban_members: 2,
      administrator: 3,
      manage_channels: 4,
      manage_guild: 5,
      add_reactions: 6,
      view_audit_log: 7,
      priority_speaker: 8,
      stream: 9,
      view_channel: 10,
      send_messages: 11,
      send_tts_messages: 12,
      manage_messages: 13,
      embed_links: 14,
      attach_files: 15,
      read_message_history: 16,
      mention_everyone: 17,
      use_external_emojis: 18,
      view_guild_insights: 19,
      connect: 20,
      speak: 21,
      mute_members: 22,
      deafen_members: 23,
      move_members: 24,
      use_vad: 25,
      change_nickname: 26,
      manage_nicknames: 27,
      manage_roles: 28,
      manage_webhooks: 29,
      manage_emojis: 30,
      use_slash_commands: 31,
      request_to_speak: 32,
      manage_threads: 34,
      use_public_threads: 35,
      use_private_threads: 36,
    }.freeze
  end

  #
  # Represents a permission per channel.
  #
  class PermissionOverwrite
    # @!attribute [r] allow
    #   @return [Discorb::Permission] The allowed permissions.
    # @!attribute [r] deny
    #   @return [Discorb::Permission] The denied permissions.
    # @!attribute [r] allow_value
    #   @return [Integer] The allowed permissions as an integer.
    # @!attribute [r] deny_value
    #   @return [Integer] The denied permissions as an integer.

    @raw_bits = {
      create_instant_invite: 0,
      kick_members: 1,
      ban_members: 2,
      administrator: 3,
      manage_channels: 4,
      manage_guild: 5,
      add_reactions: 6,
      view_audit_log: 7,
      priority_speaker: 8,
      stream: 9,
      view_channel: 10,
      send_messages: 11,
      send_tts_messages: 12,
      manage_messages: 13,
      embed_links: 14,
      attach_files: 15,
      read_message_history: 16,
      mention_everyone: 17,
      use_external_emojis: 18,
      view_guild_insights: 19,
      connect: 20,
      speak: 21,
      mute_members: 22,
      deafen_members: 23,
      move_members: 24,
      use_vad: 25,
      change_nickname: 26,
      manage_nicknames: 27,
      manage_roles: 28,
      manage_webhooks: 29,
      manage_emojis: 30,
      use_slash_commands: 31,
      request_to_speak: 32,
      manage_threads: 34,
      use_public_threads: 35,
      use_private_threads: 36,
    }.freeze
    @bits = @raw_bits.transform_values { |v| 1 << v }.freeze

    #
    # Initializes a new PermissionOverwrite.
    # @private
    #
    # @param allow [Integer] The allowed permissions.
    # @param deny [Integer] The denied permissions.
    #
    def initialize(allow, deny)
      @allow = allow
      @deny = deny
    end

    def allow
      self.class.bits.keys.filter { |field| @allow & self.class.bits[field] != 0 }
    end

    alias +@ allow

    def deny
      self.class.bits.keys.filter { |field| @deny & self.class.bits[field] != 0 }
    end

    alias -@ deny

    def allow_value
      @allow
    end

    def deny_value
      @deny
    end

    def inspect
      "#<#{self.class} allow=#{allow} deny=#{deny}>"
    end

    #
    # Converts the permission overwrite to a hash.
    #
    # @return [Hash] The permission overwrite as a hash.
    #
    def to_hash
      self.class.bits.keys.to_h do |field|
        [
          field,
          if @allow & self.class.bits[field] != 0
            true
          elsif @deny & self.class.bits[field] != 0
            false
          end,
        ]
      end
    end

    #
    # Union of the permission overwrites.
    #
    # @param [Discorb::PermissionOverwrite] other The other permission overwrite.
    #
    # @return [Discorb::PermissionOverwrite] The union of the permission overwrites.
    #
    def +(other)
      result = to_hash
      self.class.bits.each_key do |field|
        unless other[field].nil?
          result[field] = (other[field] || raise(KeyError, "field #{field} not found in #{other.inspect}"))
        end
      end
      self.class.from_hash(result)
    end

    #
    # Returns whether overwrite of the given field.
    #
    # @param [Symbol] field The field to check.
    #
    # @return [true, false, nil] Whether the field is allowed, denied or not set.
    #
    def [](field)
      if @allow & self.class.bits[field] != 0
        true
      elsif @deny & self.class.bits[field] != 0
        false
      end
    end

    #
    # Sets the given field to the given value.
    #
    # @param [Symbol] key The field to set.
    # @param [Boolean] bool The value to set.
    #
    def []=(key, bool)
      case bool
      when true
        @allow |= self.class.bits[key]
        @deny &= ~self.class.bits[key]
      when false
        @allow &= ~self.class.bits[key]
        @deny |= self.class.bits[key]
      else
        @allow &= ~self.class.bits[key]
        @deny &= ~self.class.bits[key]
      end
    end

    #
    # (see Flag#method_missing)
    #
    def method_missing(method, bool = nil)
      if self.class.bits.key?(method)
        self[method]
      elsif self.class.bits.key?(method.to_s.delete_suffix("=").to_sym)
        key = method.to_s.delete_suffix("=").to_sym
        self[key] = bool
      else
        super
      end
    end

    def respond_to_missing?(method, _arg)
      self.class.bits.key?(method.to_s.delete_suffix("=").to_sym) ? true : super
    end

    class << self
      # @private
      attr_reader :bits

      #
      # Initializes a permission overwrite from a hash.
      #
      # @param [Hash] hash The hash to initialize the permission overwrite from.
      #
      # @return [Discorb::PermissionOverwrite] The permission overwrite.
      #
      def from_hash(hash)
        allow = 0
        deny = 0
        hash.filter { |k, v| self.class.bits.keys.include?(k) && [true, false].include?(v) }.each do |k, v|
          if v
            allow += self.class.bits[k]
          else
            deny += self.class.bits[k]
          end
        end

        new(allow, deny)
      end
    end
  end
end
