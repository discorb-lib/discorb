# frozen_string_literal: true

module Discorb
  #
  # Represents a member of a guild.
  #
  class Member < User
    # @return [Time] The time the member boosted the guild.
    attr_reader :premium_since
    # @return [String] The nickname of the member.
    # @return [nil] If the member has no nickname.
    attr_reader :nick
    # @return [Time] The time the member joined the guild.
    attr_reader :joined_at
    # @return [Discorb::Asset] The custom avatar of the member.
    # @return [nil] If the member has no custom avatar.
    attr_reader :custom_avatar
    # @return [Discorb::Asset] The display avatar of the member.
    attr_reader :display_avatar
    # @return [Boolean] Whether the member is muted.
    attr_reader :mute
    alias mute? mute
    # @return [Boolean] Whether the member is deafened.
    attr_reader :deaf
    alias deaf? deaf
    # @return [Boolean] Whether the member is pending (Not passed member screening).
    attr_reader :pending
    alias pending? pending

    # @!attribute [r] name
    #   @return [String] The display name of the member.
    # @!attribute [r] mention
    #   @return [String] The mention of the member.
    # @!attribute [r] voice_state
    #   @return [Discorb::VoiceState] The voice state of the member.
    # @!attribute [r] roles
    #   @macro client_cache
    #   @return [Array<Discorb::Role>] The roles of the member.
    # @!attribute [r] guild
    #   @macro client_cache
    #   @return [Discorb::Guild] The guild the member is in.
    # @!attribute [r] hoisted_role
    #   @macro client_cache
    #   @return [Discorb::Role] The hoisted role of the member.
    #   @return [nil] If the member has no hoisted role.
    # @!attribute [r] hoisted?
    #   @return [Boolean] Whether the member has a hoisted role.
    # @!attribute [r] permissions
    #   @return [Discorb::Permission] The permissions of the member.
    # @!attribute [r] presence
    #   @macro client_cache
    #   @return [Discorb::Presence] The presence of the member.
    # @!attribute [r] activity
    #   @macro client_cache
    #   @return [Discorb::Presence::Activity] The activity of the member. It's from the {#presence}.
    # @!attribute [r] activities
    #   @macro client_cache
    #   @return [Array<Discorb::Presence::Activity>] The activities of the member. It's from the {#presence}.
    # @!attribute [r] status
    #   @macro client_cache
    #   @return [Symbol] The status of the member. It's from the {#presence}.
    # @!attribute [r] owner?
    #   @return [Boolean] Whether the member is the owner of the guild.

    #
    # Initialize a new instance of the member.
    # @private
    #
    # @param [Discorb::Client] client The client.
    # @param [Discorb::Snowflake] guild_id The ID of the guild.
    # @param [Hash] user_data The data of the user.
    # @param [Hash] member_data The data of the member.
    #
    def initialize(client, guild_id, user_data, member_data)
      @guild_id = guild_id
      @client = client
      @_member_data = {}
      @data = {}
      _set_data(user_data, member_data)
    end

    #
    # Format the member to `Username#Discriminator` style.
    #
    # @return [String] The formatted member.
    #
    def to_s
      if @discriminator == "0"
        "#{name} (@#{@username})"
      else
        "#{username}##{discriminator}"
      end
    end

    def name
      @nick || @global_name || @username
    end

    def mention
      "<@#{@nick.nil? ? "" : "!"}#{@id}>"
    end

    def voice_state
      guild.voice_states[@id]
    end

    def owner?
      guild.owner_id == @id
    end

    def guild
      @client.guilds[@guild_id]
    end

    def roles
      @role_ids.map { |r| guild.roles[r] }.sort_by(&:position).reverse +
        [guild.roles[guild.id]]
    end

    def permissions
      return Permission.new((1 << 38) - 1) if owner?

      roles.map(&:permissions).sum(Permission.new(0))
    end

    alias guild_permissions permissions

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

    #
    # Add a role to the member.
    # @async
    #
    # @param [Discorb::Role] role The role to add.
    # @param [String] reason The reason for the action.
    #
    # @return [Async::Task<void>] The task.
    #
    def add_role(role, reason: nil)
      Async do
        @client
          .http
          .request(
            Route.new(
              "/guilds/#{@guild_id}/members/#{@id}/roles/#{role.is_a?(Role) ? role.id : role}",
              "//guilds/:guild_id/members/:user_id/roles/:role_id",
              :put
            ),
            nil,
            audit_log_reason: reason
          )
          .wait
      end
    end

    #
    # Remove a role to the member.
    # @async
    #
    # @param [Discorb::Role] role The role to add.
    # @param [String] reason The reason for the action.
    #
    # @return [Async::Task<void>] The task.
    #
    def remove_role(role, reason: nil)
      Async do
        @client
          .http
          .request(
            Route.new(
              "/guilds/#{@guild_id}/members/#{@id}/roles/#{role.is_a?(Role) ? role.id : role}",
              "//guilds/:guild_id/members/:user_id/roles/:role_id",
              :delete
            ),
            {},
            audit_log_reason: reason
          )
          .wait
      end
    end

    #
    # Edit the member.
    # @async
    # @macro edit
    #
    # @param [String] nick The nickname of the member.
    # @param [Discorb::Role] role The roles of the member.
    # @param [Boolean] mute Whether the member is muted.
    # @param [Boolean] deaf Whether the member is deafened.
    # @param [Discorb::StageChannel] channel The channel the member is moved to.
    # @param [Time, nil] communication_disabled_until The time the member is timed out. Set to `nil` to end the timeout.
    # @param [Time, nil] timeout_until Alias of `communication_disabled_until`.
    # @param [String] reason The reason for the action.
    #
    # @return [Async::Task<void>] The task.
    #
    def edit(
      nick: Discorb::Unset,
      role: Discorb::Unset,
      mute: Discorb::Unset,
      deaf: Discorb::Unset,
      channel: Discorb::Unset,
      communication_disabled_until: Discorb::Unset,
      timeout_until: Discorb::Unset,
      reason: nil
    )
      Async do
        payload = {}
        payload[:nick] = nick if nick != Discorb::Unset
        payload[:roles] = role if role != Discorb::Unset
        payload[:mute] = mute if mute != Discorb::Unset
        payload[:deaf] = deaf if deaf != Discorb::Unset
        communication_disabled_until = timeout_until if timeout_until !=
          Discorb::Unset
        if communication_disabled_until != Discorb::Unset
          payload[
            :communication_disabled_until
          ] = communication_disabled_until&.iso8601
        end
        payload[:channel_id] = channel&.id if channel != Discorb::Unset
        @client
          .http
          .request(
            Route.new(
              "/guilds/#{@guild_id}/members/#{@id}",
              "//guilds/:guild_id/members/:user_id",
              :patch
            ),
            payload,
            audit_log_reason: reason
          )
          .wait
      end
    end

    alias modify edit

    #
    # Timeout the member.
    # @async
    #
    # @param [Time] time The time until the member is timeout.
    # @param [String] reason The reason for the action.
    #
    # @return [Async::Task<void>] The task.
    #
    def timeout(time, reason: nil)
      edit(communication_disabled_until: time, reason: reason)
    end

    alias disable_communication timeout

    #
    # Kick the member.
    # @async
    #
    # @param [String] reason The reason for the action.
    #
    # @return [Async::Task<void>] The task.
    #
    def kick(reason: nil)
      Async { guild.kick_member(self, reason: reason).wait }
    end

    #
    # Ban the member.
    # @async
    #
    # @param [Integer] delete_message_days The number of days to delete messages.
    # @param [String] reason The reason for the action.
    #
    # @return [Async::Task<Discorb::Guild::Ban>] The ban.
    #
    def ban(delete_message_days: 0, reason: nil)
      Async do
        guild.ban_member(
          self,
          delete_message_days: delete_message_days,
          reason: reason
        ).wait
      end
    end

    #
    # Checks if the member can manage the given role.
    #
    # @param [Discorb::Role] role The role.
    #
    # @return [Boolean] `true` if the member can manage the role.
    #
    def can_manage?(role)
      return true if owner?

      top_role = roles.max_by(&:position)
      top_role.position > role.position
    end

    private

    def _set_data(user_data, member_data)
      user_data ||= member_data[:user]
      @role_ids = member_data[:roles]
      @premium_since =
        member_data[:premium_since] && Time.iso8601(member_data[:premium_since])
      @pending = member_data[:pending]
      @nick = member_data[:nick]
      @mute = member_data[:mute]
      @joined_at =
        member_data[:joined_at] && Time.iso8601(member_data[:joined_at])
      @hoisted_role_id = member_data[:hoisted_role]
      @deaf = member_data[:deaf]
      @custom_avatar =
        member_data[:avatar] && Asset.new(self, member_data[:avatar])
      super(user_data)
      @display_avatar = @custom_avatar || @avatar
      @client.guilds[@guild_id].members[@id] = self unless @guild_id.nil? ||
        @client.guilds[@guild_id].nil?
      @_member_data.update(member_data)
    end
  end
end
