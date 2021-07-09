# frozen_string_literal: true

require_relative 'flag'

module Discorb
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
      use_private_threads: 36
    }.freeze
  end

  class PermissionOverwrite
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
      use_private_threads: 36
    }.freeze
    @bits = @raw_bits.transform_values { |v| 1 << v }.freeze
    def initialize(allow, deny)
      @allow = allow
      @deny = deny
    end

    def allow
      self.class.bits.keys.filter { |field| @allow & self.class.bits[field] != 0 }
    end

    def deny
      self.class.bits.keys.filter { |field| @deny & self.class.bits[field] != 0 }
    end

    def allow_value
      @allow
    end

    def deny_value
      @deny
    end

    def to_hash
      self.class.bits.keys.map do |field|
        [field, if @allow & self.class.bits[field] != 0
                  true
                elsif @deny & self.class.bits[method] != 0
                  false
                end]
      end.to_h
    end

    def +(other)
      result = to_hash
      self.class.bits.each_key do |field|
        result[field] = other[field] unless other[field].nil?
      end
      self.class.from_hash(result)
    end

    def [](field)
      if @allow & self.class.bits[field] != 0
        true
      elsif @deny & self.class.bits[field] != 0
        false
      end
    end

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

    def method_missing(method, bool = nil)
      if self.class.bits.key?(method)
        self[method]
      elsif self.class.bits.key?(method.to_s.delete_suffix('=').to_sym)
        key = method.to_s.delete_suffix('=').to_sym
        self[key] = bool
      else
        super
      end
    end

    def respond_to_missing?(method, _arg)
      self.class.bits.key?(method.to_s.delete_suffix('=').to_sym) ? true : super
    end
    class << self
      attr_reader :bits

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
