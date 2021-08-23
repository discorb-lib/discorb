# frozen_string_literal: true

module Discorb
  class Member < User
    attr_reader :premium_since, :nick, :joined_at, :custom_avatar, :display_avatar, :avatar, :mute, :deaf, :pending
    alias mute? mute
    alias deaf? deaf
    alias pending? pending

    def initialize(client, guild_id, user_data, member_data)
      @guild_id = guild_id
      @client = client
      @_member_data = {}
      @data = {}
      _set_data(user_data, member_data)
    end

    def to_s
      "@#{name}"
    end

    def name
      @nick || @username
    end

    def mention
      "<@#{@nick.nil? ? '' : '!'}#{@id}>"
    end

    def voice_state
      guild.voice_states[@id]
    end

    def guild
      @client.guilds[@guild_id]
    end

    def roles
      @role_ids.map { |r| guild.roles[r] }
    end

    def permissions
      roles.map(&:permissions).sum(Permission.new(0))
    end

    def hoisted_role
      @hoisted_role_id && guild.roles[@hoisted_role_id]
    end

    def hoisted?
      !@hoisted_role_id.nil?
    end

    def presence
      guild.presences[@id]
    end

    def activity
      presence&.activity
    end

    def activities
      presence&.activities
    end

    def status
      presence&.status
    end

    def inspect
      "#<#{self.class} #{self} id=#{@id}>"
    end

    # HTTP

    def add_role(role, reason: nil)
      @client.internet.put("/guilds/#{@guild_id}/members/#{@id}/roles/#{role.is_a?(Role) ? role.id : role}", nil, audit_log_reason: reason)
    end

    def remove_role(role, reason: nil)
      @client.internet.delete("/guilds/#{@guild_id}/members/#{@id}/roles/#{role.is_a?(Role) ? role.id : role}", audit_log_reason: reason)
    end

    def edit(nick: :unset, role: :unset, mute: :unset, deaf: :unset, channel: :unset, reason: nil)
      Async do
        payload = {}
        payload[:nick] = nick if nick != :unset
        payload[:roles] = role if role != :unset
        payload[:mute] = mute if mute != :unset
        payload[:deaf] = deaf if deaf != :unset
        payload[:channel_id] = channel&.id if channel != :unset
        @client.internet.patch("/guilds/#{@guild_id}/members/#{@id}", payload, audit_log_reason: reason).wait
      end
    end

    alias modify edit

    def kick(reason: nil)
      Async do
        guild.kick_member(self, reason: reason).wait
      end
    end

    def ban(delete_message_days: 0, reason: nil)
      Async do
        guild.ban_member(self, delete_message_days: delete_message_days, reason: reason).wait
      end
    end

    private

    def _set_data(user_data, member_data)
      user_data ||= member_data[:user]
      @role_ids = member_data[:roles]
      @premium_since = member_data[:premium_since] && Time.iso8601(member_data[:premium_since])
      @pending = member_data[:pending]
      @nick = member_data[:nick]
      @mute = member_data[:mute]
      @joined_at = member_data[:joined_at] && Time.iso8601(member_data[:joined_at])
      @hoisted_role_id = member_data[:hoisted_role]
      @deaf = member_data[:deaf]
      @custom_avatar = member_data[:avatar]
      @display_avatar = Asset.new(self, member_data[:avatar] || user_data[:avatar])
      super(user_data)
      @client.guilds[@guild_id].members[@id] = self unless @guild_id.nil?
      @_member_data.update(member_data)
    end
  end
end
