# frozen_string_literal: true

module Discorb
  #
  # Represents a guild in the Discord.
  #
  class Guild < DiscordModel
    # @return [Discorb::Snowflake] ID of the guild.
    attr_reader :id
    # @return [String] The name of the guild.
    attr_reader :name
    # @return [Discorb::Asset] The splash of the guild.
    attr_reader :splash
    # @return [Discorb::Asset] The discovery splash of the guild.
    attr_reader :discovery_splash
    # @return [Discorb::Snowflake] ID of the guild owner.
    attr_reader :owner_id
    # @return [Discorb::Permission] The bot's permission in the guild.
    attr_reader :permissions
    # @return [Integer] The AFK timeout of the guild.
    attr_reader :afk_timeout
    # @return [Discorb::Dictionary{Discorb::Snowflake => Discorb::Role}] A dictionary of roles in the guild.
    attr_reader :roles
    # @return [Discorb::Dictionary{Discorb::Snowflake => Discorb::CustomEmoji}] A dictionary of custom emojis in the guild.
    attr_reader :emojis
    # @return [Array<Symbol>] features that are enabled in the guild.
    # @see https://discord.com/developers/docs/resources/guild#guild-object-guild-features Official Discord API docs
    attr_reader :features
    # @return [:none, :elevated] The MFA level of the guild.
    attr_reader :mfa_level
    # @return [Discorb::Guild::SystemChannelFlag] The flag for the system channel.
    attr_reader :system_channel_flags
    # @return [Time] Time that representing when bot has joined the guild.
    attr_reader :joined_at
    # @return [Boolean] Whether the guild is unavailable.
    attr_reader :unavailable
    # @return [Integer] The amount of members in the guild.
    attr_reader :member_count
    # @return [Discorb::Asset] The icon of the guild.
    attr_reader :icon
    # @return [Discorb::Dictionary{Discorb::User => Discorb::VoiceState}] A dictionary of voice states in the guild.
    attr_reader :voice_states
    # @return [Discorb::Dictionary{Discorb::Snowflake => Discorb::Member}] A dictionary of members in the guild.
    # @macro members_intent
    attr_reader :members
    # @return [Discorb::Dictionary{Discorb::Snowflake => Discorb::GuildChannel}] A dictionary of channels in the guild.
    attr_reader :channels
    # @return [Discorb::Dictionary{Discorb::Snowflake => Discorb::ThreadChannel}] A dictionary of threads in the guild.
    attr_reader :threads
    # @return [Discorb::Dictionary{Discorb::User => Discorb::Presence}] A dictionary of presence in the guild.
    attr_reader :presences
    # @return [Integer] Number of online members in the guild.
    attr_reader :max_presences
    # @return [String] The vanity invite URL for the guild.
    # @return [nil] If the guild does not have a vanity invite URL.
    attr_reader :vanity_url_code
    # @return [String] The description of the guild.
    attr_reader :description
    # @return [Discorb::Asset] The banner of the guild.
    # @return [nil] If the guild does not have a banner.
    attr_reader :banner
    # @return [Integer] The premium tier (Boost Level) of the guild.
    attr_reader :premium_tier
    # @return [Integer] The amount of premium subscriptions (Server Boosts) the guild has.
    attr_reader :premium_subscription_count
    # @return [Symbol] The preffered language of the guild.
    # @note This modifies the language code, `-` will be replaced with `_`.
    attr_reader :preferred_locale
    # @return [Integer] The maximum amount of users in a video channel.
    attr_reader :max_video_channel_users
    # @return [Integer] The approxmate amount of members in the guild.
    attr_reader :approximate_member_count
    # @return [Integer] The approxmate amount of non-offline members in the guild.
    attr_reader :approximate_presence_count
    # @return [Discorb::WelcomeScreen] The welcome screen of the guild.
    attr_reader :welcome_screen
    # @return [:default, :explicit, :safe, :age_restricted] The nsfw level of the guild.
    attr_reader :nsfw_level
    # @return [Discorb::Dictionary{Discorb::Snowflake => Discorb::StageInstance}] A dictionary of stage instances in the guild.
    attr_reader :stage_instances
    # @return [:none, :low, :medium, :high, :very_high] The verification level of the guild.
    attr_reader :verification_level
    # @return [:all_messages, :only_mentions] The default message notification level of the guild.
    attr_reader :default_message_notifications
    # @return [:disabled_in_text, :members_without_roles, :all_members] The explict content filter level of the guild.
    attr_reader :explicit_content_filter
    # @return [Boolean] Whether the client is the owner of the guild.
    attr_reader :owner
    alias owner? owner
    # @return [Boolean] Whether the guild is large.
    attr_reader :large
    alias large? large
    # @return [Boolean] Whether the guild enabled the widget.
    attr_reader :widget_enabled
    alias widget_enabled? widget_enabled
    # @return [Boolean] Whether the guild is available.
    attr_reader :available
    alias available? available

    # @!attribute [r] afk_channel
    #   @return [Discorb::VoiceChannel] The AFK channel for this guild.
    #   @macro client_cache
    # @!attribute [r] system_channel
    #   @return [Discorb::TextChannel] The system message channel for this guild.
    #   @macro client_cache
    # @!attribute [r] rules_channel
    #   @return [Discorb::TextChannel] The rules channel for this guild.
    #   @macro client_cache
    # @!attribute [r] public_updates_channel
    #   @return [Discorb::TextChannel] The public updates channel (`#moderator-only`) for this guild.
    #   @macro client_cache
    # @!attribute [r] me
    #   @return [Discorb::Member] The client's member in the guild.

    @mfa_levels = %i[none elevated].freeze
    @nsfw_levels = %i[default explicit safe age_restricted].freeze
    @verification_levels = %i[none low medium high very_high].freeze
    @default_message_notifications = %i[all_messages only_mentions].freeze
    @explicit_content_filter = %i[disabled_in_text members_without_roles all_members].freeze

    # @!visibility private
    def initialize(client, data, is_create_event)
      @client = client
      @data = {}
      _set_data(data, is_create_event)
    end

    # @!visibility private
    def update!
      Async do
        _, data = @client.get("/guilds/#{@id}").wait
        _set_data(data, false)
      end
    end

    def afk_channel
      @client.channels[@afk_channel_id]
    end

    def system_channel
      @client.channels[@system_channel_id]
    end

    def rules_channel
      @client.channels[@rules_channel_id]
    end

    def public_updates_channel
      @client.channels[@public_updates_channel_id]
    end

    def inspect
      "#<#{self.class} \"#{@name}\" id=#{@id}>"
    end

    def me
      @members[@client.user.id]
    end

    #
    # Leave the guild.
    # @macro async
    # @macro http
    #
    def leave!
      Async do
        @client.http.delete("/users/@me/guilds/#{@id}").wait
        @client.guilds.delete(@id)
      end
    end

    #
    # Fetch emoji list of the guild.
    # @macro async
    # @macro http
    # @note This querys the API every time. We recommend using {#emojis} instead.
    #
    # @return [Async::Task<Discorb::Dictionary{Discorb::Snowflake => Discorb::CustomEmoji}>] A dictionary of emoji in the guild.
    #
    def fetch_emoji_list
      Async do
        _resp, data = @client.http.get("/guilds/#{@id}/emojis").wait
        @emojis = Dictionary.new
        ids = @emojis.map(&:id).map(&:to_s)
        data.map do |e|
          next if ids.include?(e[:id])

          @emojis[e[:id]] = CustomEmoji.new(@client, self, e)
        end
        @emojis
      end
    end

    alias fetch_emojis fetch_emoji_list

    #
    # Fetch emoji id of the guild.
    # @macro async
    # @macro http
    # @note This querys the API every time. We recommend using {#emojis} instead.
    #
    # @param [#to_s] id The emoji id.
    #
    # @return [Async::Task<Discorb::CustomEmoji>] The emoji with the given id.
    #
    def fetch_emoji(id)
      _resp, data = @client.http.get("/guilds/#{@id}/emojis/#{id}").wait
      @emojis[e[:id]] = CustomEmoji.new(@client, self, data)
    end

    #
    # Create a custom emoji.
    # @macro async
    # @macro http
    #
    # @param [#to_s] name The name of the emoji.
    # @param [Discorb::Image] image The image of the emoji.
    # @param [Array<Discorb::Role>] roles A list of roles to give the emoji.
    #
    # @return [Async::Task<Discorb::CustomEmoji>] The created emoji.
    #
    def create_emoji(name, image, roles: [])
      _resp, data = @client.http.post(
        "/guilds/#{@id}/emojis",
        {
          name: name,
          image: image.to_s,
          roles: roles.map { |r| Discorb::Utils.try(r, :id) },
        }
      ).wait
      @emojis[data[:id]] = CustomEmoji.new(@client, self, data)
    end

    #
    # Fetch webhooks of the guild.
    # @macro async
    # @macro http
    #
    # @return [Async::Task<Array<Discorb::Webhook>>] A list of webhooks in the guild.
    #
    def fetch_webhooks
      Async do
        _resp, data = @client.http.get("/guilds/#{@id}/webhooks").wait
        data.map { |webhook| Webhook.new([@client, webhook]) }
      end
    end

    #
    # Fetch audit log of the guild.
    # @macro async
    # @macro http
    #
    # @return [Async::Task<Discorb::AuditLog>] The audit log of the guild.
    #
    def fetch_audit_log
      Async do
        _resp, data = @client.http.get("/guilds/#{@id}/audit-logs").wait
        AuditLog.new(@client, data, self)
      end
    end

    #
    # Fetch channels of the guild.
    # @macro async
    # @macro http
    #
    # @return [Async::Task<Array<Discorb::Channel>>] A list of channels in the guild.
    #
    def fetch_channels
      Async do
        _resp, data = @client.http.get("/guilds/#{@id}/channels").wait
        data.map { |c| Channel.make_channel(@client, c) }
      end
    end

    #
    # Create a new text channel.
    # @macro async
    # @macro http
    #
    # @param [String] name The name of the channel.
    # @param [String] topic The topic of the channel.
    # @param [Integer] rate_limit_per_user The rate limit per user in the channel.
    # @param [Integer] slowmode Alias for `rate_limit_per_user`.
    # @param [Integer] position The position of the channel.
    # @param [Boolean] nsfw Whether the channel is nsfw.
    # @param [Hash{Discorb::Role, Discorb::Member => Discorb::PermissionOverwrite}] permission_overwrites A list of permission overwrites.
    # @param [Discorb::CategoryChannel] parent The parent of the channel.
    # @param [String] reason The reason for creating the channel.
    #
    # @return [Async::Task<Discorb::TextChannel>] The created text channel.
    #
    def create_text_channel(
      name, topic: nil, rate_limit_per_user: nil, slowmode: nil, position: nil, nsfw: nil, permission_overwrites: nil, parent: nil, reason: nil
    )
      Async do
        payload = { type: TextChannel.channel_type }
        payload[:name] = name
        payload[:topic] = topic if topic
        rate_limit_per_user ||= slowmode
        payload[:rate_limit_per_user] = rate_limit_per_user if rate_limit_per_user
        payload[:nsfw] = nsfw if nsfw
        payload[:position] = position if position
        if permission_overwrites
          payload[:permission_overwrites] = permission_overwrites.map do |target, overwrite|
            {
              type: target.is_a?(Role) ? 0 : 1,
              id: target.id,
              allow: overwrite.allow_value,
              deny: overwrite.deny_value,
            }
          end
        end
        payload[:parent_id] = parent.id if parent
        _resp, data = @client.http.post(
          "/guilds/#{@id}/channels", payload, audit_log_reason: reason,
        ).wait
        payload[:parent_id] = parent&.id
        Channel.make_channel(@client, data)
      end
    end

    #
    # Create a new voice channel.
    # @macro async
    # @macro http
    #
    # @param [String] name The name of the channel.
    # @param [Integer] bitrate The bitrate of the channel.
    # @param [Integer] user_limit The user limit of the channel.
    # @param [Integer] position The position of the channel.
    # @param [Hash{Discorb::Role, Discorb::Member => Discorb::PermissionOverwrite}] permission_overwrites A list of permission overwrites.
    # @param [Discorb::CategoryChannel] parent The parent of the channel.
    # @param [String] reason The reason for creating the channel.
    #
    # @return [Async::Task<Discorb::VoiceChannel>] The created voice channel.
    #
    def create_voice_channel(
      name, bitrate: 64, user_limit: nil, position: nil, permission_overwrites: nil, parent: nil, reason: nil
    )
      Async do
        payload = { type: VoiceChannel.channel_type }
        payload[:name] = name
        payload[:bitrate] = bitrate * 1000 if bitrate
        payload[:user_limit] = user_limit if user_limit
        payload[:position] = position if position
        if permission_overwrites
          payload[:permission_overwrites] = permission_overwrites.map do |target, overwrite|
            {
              type: target.is_a?(Role) ? 0 : 1,
              id: target.id,
              allow: overwrite.allow_value,
              deny: overwrite.deny_value,
            }
          end
        end
        payload[:parent_id] = parent.id if parent
        _resp, data = @client.http.post(
          "/guilds/#{@id}/channels", payload, audit_log_reason: reason,
        ).wait
        payload[:parent_id] = parent&.id
        Channel.make_channel(@client, data)
      end
    end

    # Create a new category channel.
    # @macro async
    # @macro http
    #
    # @param [String] name The name of the channel.
    # @param [Integer] position The position of the channel.
    # @param [Hash{Discorb::Role, Discorb::Member => Discorb::PermissionOverwrite}] permission_overwrites A list of permission overwrites.
    # @param [Discorb::CategoryChannel] parent The parent of the channel.
    # @param [String] reason The reason for creating the channel.
    #
    # @return [Async::Task<Discorb::CategoryChannel>] The created category channel.
    #
    def create_category_channel(name, position: nil, permission_overwrites: nil, parent: nil, reason: nil)
      Async do
        payload = { type: CategoryChannel.channel_type }
        payload[:name] = name
        payload[:position] = position if position
        if permission_overwrites
          payload[:permission_overwrites] = permission_overwrites.map do |target, overwrite|
            {
              type: target.is_a?(Role) ? 0 : 1,
              id: target.id,
              allow: overwrite.allow_value,
              deny: overwrite.deny_value,
            }
          end
        end
        payload[:parent_id] = parent&.id
        _resp, data = @client.http.post(
          "/guilds/#{@id}/channels", payload, audit_log_reason: reason,
        ).wait
        Channel.make_channel(@client, data)
      end
    end

    alias create_category create_category_channel

    #
    # Create a new stage channel.
    # @macro async
    # @macro http
    #
    # @param [String] name The name of the channel.
    # @param [Integer] bitrate The bitrate of the channel.
    # @param [Integer] position The position of the channel.
    # @param [Hash{Discorb::Role, Discorb::Member => Discorb::PermissionOverwrite}] permission_overwrites A list of permission overwrites.
    # @param [Discorb::CategoryChannel] parent The parent of the channel.
    # @param [String] reason The reason for creating the channel.
    #
    # @return [Async::Task<Discorb::StageChannel>] The created stage channel.
    #
    def create_stage_channel(name, bitrate: 64, position: nil, permission_overwrites: nil, parent: nil, reason: nil)
      Async do
        payload = { type: StageChannel.channel_type }
        payload[:name] = name
        payload[:bitrate] = bitrate * 1000 if bitrate
        payload[:position] = position if position
        if permission_overwrites
          payload[:permission_overwrites] = permission_overwrites.map do |target, overwrite|
            {
              type: target.is_a?(Role) ? 0 : 1,
              id: target.id,
              allow: overwrite.allow_value,
              deny: overwrite.deny_value,
            }
          end
        end
        payload[:parent_id] = parent&.id
        _resp, data = @client.http.post(
          "/guilds/#{@id}/channels", payload, audit_log_reason: reason,
        ).wait
        Channel.make_channel(@client, data)
      end
    end

    #
    # Create a new news channel.
    # @macro async
    # @macro http
    #
    # @param [String] name The name of the channel.
    # @param [String] topic The topic of the channel.
    # @param [Integer] rate_limit_per_user The rate limit per user in the channel.
    # @param [Integer] slowmode Alias for `rate_limit_per_user`.
    # @param [Integer] position The position of the channel.
    # @param [Boolean] nsfw Whether the channel is nsfw.
    # @param [Hash{Discorb::Role, Discorb::Member => Discorb::PermissionOverwrite}] permission_overwrites A list of permission overwrites.
    # @param [Discorb::CategoryChannel] parent The parent of the channel.
    # @param [String] reason The reason for creating the channel.
    #
    # @return [Async::Task<Discorb::NewsChannel>] The created news channel.
    #
    def create_news_channel(
      name, topic: nil, rate_limit_per_user: nil, slowmode: nil, position: nil, nsfw: nil, permission_overwrites: nil, parent: nil, reason: nil
    )
      Async do
        payload = { type: NewsChannel.channel_type }
        payload[:name] = name
        payload[:topic] = topic if topic
        rate_limit_per_user ||= slowmode
        payload[:rate_limit_per_user] = rate_limit_per_user if rate_limit_per_user
        payload[:position] = position if position
        if permission_overwrites
          payload[:permission_overwrites] = permission_overwrites.map do |target, overwrite|
            {
              type: target.is_a?(Role) ? 0 : 1,
              id: target.id,
              allow: overwrite.allow_value,
              deny: overwrite.deny_value,
            }
          end
        end
        payload[:nsfw] = nsfw unless nsfw.nil?
        payload[:parent_id] = parent&.id
        _resp, data = @client.http.post(
          "/guilds/#{@id}/channels", payload, audit_log_reason: reason,
        ).wait
        Channel.make_channel(@client, data)
      end
    end

    #
    # Fetch a list of active threads in the guild.
    # @macro async
    # @macro http
    #
    # @return [Async::Task<Array<Discorb::ThreadChannel>>] The list of threads.
    #
    def fetch_active_threads
      Async do
        _resp, data = @client.http.get("/guilds/#{@id}/threads/active").wait
        data[:threads].map { |t| Channel.make_thread(@client, t) }
      end
    end

    #
    # Fetch a member in the guild.
    # @macro async
    # @macro http
    #
    # @param [#to_s] id The ID of the member to fetch.
    #
    # @return [Async::Task<Discorb::Member>] The member.
    # @return [Async::Task<nil>] If the member is not found.
    #
    def fetch_member(id)
      Async do
        _resp, data = @client.http.get("/guilds/#{@id}/members/#{id}").wait
      rescue Discorb::NotFoundError
        nil
      else
        Member.new(@client, @id, data[:user], data)
      end
    end

    # Fetch members in the guild.
    # @macro async
    # @macro http
    # @macro members_intent
    #
    # @param [Integer] limit The maximum number of members to fetch, 0 for all.
    # @param [Integer] after The ID of the member to start fetching after.
    #
    # @return [Async::Task<Array<Discorb::Member>>] The list of members.
    #
    def fetch_members(limit: 0, after: nil)
      Async do
        unless limit == 0
          _resp, data = @client.http.get("/guilds/#{@id}/members?#{URI.encode_www_form({ after: after, limit: limit })}").wait
          next data[:members].map { |m| Member.new(@client, @id, m[:user], m) }
        end
        ret = []
        after = 0
        loop do
          params = { after: after, limit: 100 }
          _resp, data = @client.http.get("/guilds/#{@id}/members?#{URI.encode_www_form(params)}").wait
          ret += data.map { |m| Member.new(@client, @id, m[:user], m) }
          after = data.last[:user][:id]
          if data.length != 1000
            break
          end
        end
        ret
      end
    end

    alias fetch_member_list fetch_members

    #
    # Search for members by name in the guild.
    # @macro async
    # @macro http
    #
    # @param [String] name The name of the member to search for.
    # @param [Integer] limit The maximum number of members to return.
    #
    # @return [Async::Task<Array<Discorb::Member>>] The list of members.
    #
    def fetch_members_named(name, limit: 1)
      Async do
        _resp, data = @client.http.get("/guilds/#{@id}/members/search?#{URI.encode_www_form({ query: name, limit: limit })}").wait
        data.map { |d| Member.new(@client, @id, d[:user], d) }
      end
    end

    #
    # Almost the same as {#fetch_members_named}, but returns a single member.
    # @macro async
    # @macro http
    #
    # @return [Async::Task<Discorb::Member>] The member.
    # @return [Async::Task<nil>] If the member is not found.
    #
    def fetch_member_named(...)
      Async do
        fetch_members_named(...).first
      end
    end

    #
    # Change nickname of client member.
    #
    # @param [String] nickname The nickname to set.
    # @param [String] reason The reason for changing the nickname.
    #
    def edit_nickname(nickname, reason: nil)
      Async do
        @client.http.patch("/guilds/#{@id}/members/@me/nick", { nick: nickname }, audit_log_reason: reason).wait
      end
    end

    alias edit_nick edit_nickname
    alias modify_nickname edit_nickname
    alias modify_nick modify_nickname

    #
    # Kick a member from the guild.
    # @macro async
    # @macro http
    #
    # @param [Discorb::Member] member The member to kick.
    # @param [String] reason The reason for kicking the member.
    #
    def kick_member(member, reason: nil)
      Async do
        @client.http.delete("/guilds/#{@id}/members/#{member.id}", audit_log_reason: reason).wait
      end
    end

    #
    # Fetch a list of bans in the guild.
    # @macro async
    # @macro http
    #
    # @return [Async::Task<Array<Discorb::Guild::Ban>>] The list of bans.
    #
    def fetch_bans
      Async do
        _resp, data = @client.http.get("/guilds/#{@id}/bans").wait
        data.map { |d| Ban.new(@client, self, d) }
      end
    end

    #
    # Fetch a ban in the guild.
    # @macro async
    # @macro http
    #
    # @param [Discorb::User] user The user to fetch.
    #
    # @return [Async::Task<Discorb::Guild::Ban>] The ban.
    # @return [Async::Task<nil>] If the ban is not found.
    #
    def fetch_ban(user)
      Async do
        _resp, data = @client.http.get("/guilds/#{@id}/bans/#{user.id}").wait
      rescue Discorb::NotFoundError
        nil
      else
        Ban.new(@client, self, data)
      end
    end

    #
    # Checks the user was banned from the guild.
    # @macro async
    # @macro http
    #
    # @param [Discorb::User] user The user to check.
    #
    # @return [Async::Task<Boolean>] Whether the user was banned.
    #
    def banned?(user)
      Async do
        !fetch_ban(user).wait.nil?
      end
    end

    #
    # Ban a member from the guild.
    # @macro async
    # @macro http
    #
    # @param [Discorb::Member] member The member to ban.
    # @param [Integer] delete_message_days The number of days to delete messages.
    # @param [String] reason The reason for banning the member.
    #
    # @return [Async::Task<Discorb::Guild::Ban>] The ban.
    #
    def ban_member(member, delete_message_days: 0, reason: nil)
      Async do
        _resp, data = @client.http.post(
          "/guilds/#{@id}/bans", { user: member.id, delete_message_days: delete_message_days }, audit_log_reason: reason,
        ).wait
        Ban.new(@client, self, data)
      end
    end

    #
    # Unban a user from the guild.
    # @macro async
    # @macro http
    #
    # @param [Discorb::User] user The user to unban.
    # @param [String] reason The reason for unbanning the user.
    #
    def unban_user(user, reason: nil)
      Async do
        @client.http.delete("/guilds/#{@id}/bans/#{user.id}", audit_log_reason: reason).wait
      end
    end

    #
    # Fetch a list of roles in the guild.
    # @macro async
    # @macro http
    #
    # @return [Async::Task<Array<Discorb::Role>>] The list of roles.
    #
    def fetch_roles
      Async do
        _resp, data = @client.http.get("/guilds/#{@id}/roles").wait
        data.map { |d| Role.new(@client, self, d) }
      end
    end

    #
    # Create a role in the guild.
    # @macro async
    # @macro http
    #
    # @param [String] name The name of the role.
    # @param [Discorb::Color] color The color of the role.
    # @param [Boolean] hoist Whether the role should be hoisted.
    # @param [Boolean] mentionable Whether the role should be mentionable.
    # @param [String] reason The reason for creating the role.
    #
    # @return [Async::Task<Discorb::Role>] The role.
    #
    def create_role(name = nil, color: nil, hoist: nil, mentionable: nil, reason: nil)
      Async do
        payload = {}
        payload[:name] = name if name
        payload[:color] = color.to_i if color
        payload[:hoist] = hoist if hoist
        payload[:mentionable] = mentionable if mentionable
        _resp, data = @client.http.post(
          "/guilds/#{@id}/roles", payload, audit_log_reason: reason,
        ).wait
        Role.new(@client, self, data)
      end
    end

    #
    # Fetch how many members will be pruned.
    # @macro async
    # @macro http
    #
    # @param [Integer] days The number of days to prune.
    # @param [Array<Discorb::Role>] roles The roles that include for pruning.
    #
    # @return [Async::Task<Integer>] The number of members that will be pruned.
    #
    def fetch_prune(days = 7, roles: [])
      Async do
        params = {
          days: days,
          include_roles: @id.to_s,
        }
        param[:include_roles] = roles.map(&:id).map(&:to_s).join(";") if roles.any?
        _resp, data = @client.http.get("/guilds/#{@id}/prune?#{URI.encode_www_form(params)}").wait
        data[:pruned]
      end
    end

    #
    # Prune members from the guild.
    # @macro async
    # @macro http
    #
    # @param [Integer] days The number of days to prune.
    # @param [Array<Discorb::Role>] roles The roles that include for pruning.
    # @param [String] reason The reason for pruning.
    #
    # @return [Async::Task<Integer>] The number of members that were pruned.
    #
    def prune(days = 7, roles: [], reason: nil)
      Async do
        _resp, data = @client.http.post(
          "/guilds/#{@id}/prune", { days: days, roles: roles.map(&:id) }, audit_log_reason: reason,
        ).wait
        data[:pruned]
      end
    end

    #
    # Fetch voice regions that are available in the guild.
    # @macro async
    # @macro http
    #
    # @return [Async::Task<Array<Discorb::VoiceRegion>>] The available voice regions.
    #
    def fetch_voice_regions
      Async do
        _resp, data = @client.http.get("/guilds/#{@id}/voice").wait
        data.map { |d| VoiceRegion.new(@client, d) }
      end
    end

    #
    # Fetch invites in the guild.
    # @macro async
    # @macro http
    #
    # @return [Async::Task<Array<Invite>>] The invites.
    #
    def fetch_invites
      Async do
        _resp, data = @client.http.get("/guilds/#{@id}/invites").wait
        data.map { |d| Invite.new(@client, d) }
      end
    end

    #
    # Fetch integrations in the guild.
    # @macro async
    # @macro http
    #
    # @return [Async::Task<Array<Discorb::Integration>>] The integrations.
    #
    def fetch_integrations
      Async do
        _resp, data = @client.http.get("/guilds/#{@id}/integrations").wait
        data.map { |d| Integration.new(@client, d) }
      end
    end

    #
    # Fetch the widget of the guild.
    # @macro async
    # @macro http
    #
    # @return [Async::Task<Discorb::Guild::Widget>] The widget.
    #
    def fetch_widget
      Async do
        _resp, data = @client.http.get("/guilds/#{@id}/widget").wait
        Widget.new(@client, @id, data)
      end
    end

    #
    # Fetch the vanity URL of the guild.
    # @macro async
    # @macro http
    #
    # @return [Async::Task<Discorb::Guild::VanityInvite>] The vanity URL.
    #
    def fetch_vanity_invite
      Async do
        _resp, data = @client.http.get("/guilds/#{@id}/vanity-url").wait
        VanityInvite.new(@client, self, data)
      end
    end

    #
    # Fetch the welcome screen of the guild.
    # @macro async
    # @macro http
    #
    # @return [Async::Task<Discorb::Guild::WelcomeScreen>] The welcome screen.
    #
    def fetch_welcome_screen
      Async do
        _resp, data = @client.http.get("/guilds/#{@id}/welcome-screen").wait
        WelcomeScreen.new(@client, self, data)
      end
    end

    #
    # Fetch stickers in the guild.
    # @macro async
    # @macro http
    #
    # @return [Async::Task<Array<Discorb::Sticker::GuildSticker>>] The stickers.
    #
    def fetch_stickers
      Async do
        _resp, data = @client.http.get("/guilds/#{@id}/stickers").wait
        data.map { |d| Sticker::GuildSticker.new(@client, d) }
      end
    end

    #
    # Fetch the sticker by ID.
    # @macro async
    # @macro http
    #
    # @param [#to_s] id The ID of the sticker.
    #
    # @return [Async::Task<Discorb::Sticker::GuildSticker>] The sticker.
    # @return [Async::Task<nil>] If the sticker does not exist.
    #
    def fetch_sticker(id)
      Async do
        _resp, data = @client.http.get("/guilds/#{@id}/stickers/#{id}").wait
      rescue Discorb::NotFoundError
        nil
      else
        Sticker::GuildSticker.new(@client, data)
      end
    end

    #
    # Fetch templates in the guild.
    # @macro async
    # @macro http
    #
    # @return [Async::Task<Discorb::GuildTemplate>] The templates.
    #
    def fetch_templates
      Async do
        _resp, data = @client.http.get("/guilds/#{@id}/templates").wait
        data.map { |d| GuildTemplate.new(@client, d) }
      end
    end

    #
    # Almost the same as {#fetch_templates}, but returns a single template.
    #
    # @return [Discorb::GuildTemplate] The template.
    # @return [Async::Task<nil>] If the template does not exist.
    #
    def fetch_template
      Async do
        fetch_templates.wait.first
      end
    end

    #
    # Create a new template in the guild.
    #
    # @param [String] name The name of the template.
    # @param [String] description The description of the template.
    # @param [String] reason The reason for creating the template.
    #
    # @return [Async::Task<Discorb::GuildTemplate>] The template.
    #
    def create_template(name, description = nil, reason: nil)
      Async do
        _resp, data = @client.http.post(
          "/guilds/#{@id}/templates", { name: name, description: description }, audit_log_reason: reason,
        ).wait
        GuildTemplate.new(@client, data)
      end
    end

    #
    # Represents a vanity invite.
    #
    class VanityInvite < DiscordModel
      # @return [String] The vanity invite code.
      attr_reader :code
      # @return [Integer] The number of uses.
      attr_reader :uses

      # @!attribute [r] url
      #   @return [String] The vanity URL.

      # @!visibility private
      def initialize(client, guild, data)
        @client = client
        @guild = guild
        @code = data[:code]
        @uses = data[:uses]
      end

      def url
        "https://discord.gg/#{@code}"
      end
    end

    #
    # Represents a guild widget.
    #
    class Widget < DiscordModel
      # @return [Discorb::Snowflake] The guild ID.
      attr_reader :guild_id
      # @return [Discorb::Snowflake] The channel ID.
      attr_reader :channel_id
      # @return [Boolean] Whether the widget is enabled.
      attr_reader :enabled
      alias enabled? enabled
      alias enable? enabled

      # @!attribute [r] channel
      #   @macro client_cache
      #   @return [Discorb::Channel] The channel.
      # @!attribute [r] guild
      #   @macro client_cache
      #   @return [Discorb::Guild] The guild.
      # @!attribute [r] json_url
      #   @return [String] The JSON URL.

      # @!visibility private
      def initialize(client, guild_id, data)
        @client = client
        @enabled = data[:enabled]
        @guild_id = Snowflake.new(guild_id)
        @channel_id = Snowflake.new(data[:channel_id])
      end

      def channel
        @client.channels[@channel_id]
      end

      #
      # Edit the widget.
      # @macro async
      # @macro http
      # @macro edit
      #
      # @param [Boolean] enabled Whether the widget is enabled.
      # @param [Discorb::GuildChannel] channel The channel.
      # @param [String] reason The reason for editing the widget.
      #
      def edit(enabled: nil, channel: nil, reason: nil)
        Async do
          payload = {}
          payload[:enabled] = enabled unless enabled.nil?
          payload[:channel_id] = channel.id if channel_id
          @client.http.patch("/guilds/#{@guild_id}/widget", payload, audit_log_reason: reason).wait
        end
      end

      alias modify edit

      def json_url
        "#{Discorb::API_BASE_URL}/guilds/#{@guild_id}/widget.json"
      end

      #
      # Return iframe HTML of the widget.
      #
      # @param ["dark", "light"] theme The theme of the widget.
      # @param [Integer] width The width of the widget.
      # @param [Integer] height The height of the widget.
      #
      # @return [String] The iframe HTML.
      #
      def iframe(theme: "dark", width: 350, height: 500)
        [
          %(<iframe src="https://canary.discord.com/widget?id=#{@guild_id}&theme=#{theme}" width="#{width}" height="#{height}"),
          %(allowtransparency="true" frameborder="0" sandbox="allow-popups allow-popups-to-escape-sandbox allow-same-origin allow-scripts"></iframe>),
        ].join
      end
    end

    #
    # Represents a ban.
    #
    class Ban < DiscordModel
      # @return [Discorb::User] The user.
      attr_reader :user
      # @return [String] The reason for the ban.
      attr_reader :reason

      # @!visibility private
      def initialize(client, guild, data)
        @client = client
        @guild = guild
        @reason = data[:reason]
        @user = @client.users[data[:user][:id]] || User.new(@client, data[:user])
      end
    end

    class << self
      # @!visibility private
      attr_reader :nsfw_levels, :mfa_levels, :verification_levels, :default_message_notifications, :explicit_content_filter

      #
      # Returns a banner url from the guild's ID.
      #
      # @param [#to_s] guild_id The ID of the guild.
      # @param [:shield, :banner1, :banner2, :banner3, :banner4] style The style of the banner.
      #
      # @return [String] The url of the banner.
      #
      def banner(guild_id, style: "banner")
        "#{Discorb::API_BASE_URL}/guilds/#{guild_id}/widget.png&style=#{style}"
      end
    end

    private

    def _set_data(data, is_create_event)
      @id = Snowflake.new(data[:id])
      if data[:unavailable]
        @unavailable = true
        return
      end
      @client.guilds[@id] = self unless data[:no_cache]
      @icon = data[:icon] && Asset.new(self, data[:icon])
      @unavailable = false
      @name = data[:name]
      @members = Discorb::Dictionary.new
      data[:members].each do |m|
        Member.new(@client, @id, m[:user], m)
      end if data[:members]
      @splash = data[:splash] && Asset.new(self, data[:splash], path: "splashes/#{@id}")
      @discovery_splash = data[:discovery_splash] && Asset.new(self, data[:discovery_splash], path: "discovery-splashes/#{@id}")
      @owner_id = data[:owner_id]
      @permissions = Permission.new(data[:permissions].to_i)
      @afk_channel_id = data[:afk_channel_id]
      @afk_timeout = data[:afk_timeout]
      @widget_enabled = data[:widget_enabled]
      @widget_channel_id = data[:widget_channel_id]
      @roles = Dictionary.new
      data[:roles].each do |r|
        @roles[r[:id]] = Role.new(@client, self, r)
      end
      @emojis = Dictionary.new
      data[:emojis].map do |e|
        @emojis[e[:id]] = CustomEmoji.new(@client, self, e)
      end
      @features = data[:features].map { |f| f.downcase.to_sym }
      @mfa_level = self.class.mfa_levels[data[:mfa_level]]
      @verification_level = self.class.verification_levels[data[:verification_level]]
      @default_message_notifications = self.class.default_message_notifications[data[:default_message_notifications]]
      @explicit_content_filter = self.class.explicit_content_filter[data[:explicit_content_filter]]
      @system_channel_id = data[:system_channel_id]
      @system_channel_flag = SystemChannelFlag.new(0b111 - data[:system_channel_flags])
      @rules_channel_id = data[:rules_channel_id]
      @vanity_url_code = data[:vanity_url_code]
      @description = data[:description]
      @banner = data[:banner] && Asset.new(self, data[:banner], path: "banners/#{@id}")
      @premium_tier = data[:premium_tier]
      @premium_subscription_count = data[:premium_tier_count].to_i
      @preferred_locale = data[:preferred_locale].gsub("-", "_").to_sym
      @public_updates_channel_id = data[:public_updates_channel_id]
      @max_video_channel_users = data[:max_video_channel_users]
      @approximate_member_count = data[:approximate_member_count]
      @approximate_presence_count = data[:approximate_presence_count]
      @welcome_screen = data[:welcome_screen].nil? ? nil : WelcomeScreen.new(@client, self, data[:welcome_screen])
      @nsfw_level = self.class.nsfw_levels[data[:nsfw_level]]
      return unless is_create_event

      @stickers = data[:stickers].nil? ? [] : data[:stickers].map { |s| Sticker::GuildSticker.new(self, s) }
      @joined_at = Time.iso8601(data[:joined_at])
      @large = data[:large]
      @member_count = data[:member_count]
      tmp_channels = data[:channels].filter { |c| !c.key?(:thread_metadata) }.map do |c|
        Channel.make_channel(@client, c.merge({ guild_id: @id }))
      end
      @channels = Dictionary.new(tmp_channels.map { |c| [c.id, c] }.to_h, sort: ->(c) { c[1].position })
      @voice_states = Dictionary.new(data[:voice_states].map { |v| [Snowflake.new(v[:user_id]), VoiceState.new(@client, v.merge({ guild_id: @id }))] }.to_h)
      @threads = data[:threads] ? data[:threads].map { |t| Channel.make_channel(@client, t) } : []
      @presences = Dictionary.new(data[:presences].map { |pr| [Snowflake.new(pr[:user][:id]), Presence.new(@client, pr)] }.to_h)
      @max_presences = data[:max_presences]
      @stage_instances = Dictionary.new(data[:stage_instances].map { |s| [Snowflake.new(s[:id]), StageInstance.new(@client, s)] }.to_h)
      @data.update(data)
    end
  end

  #
  # Represents a system channel flag.
  # ## Flag fields
  # |Field|Value|
  # |-|-|
  # |`1 << 0`|`:member_join`|
  # |`1 << 1`|`:server_boost`|
  # |`1 << 2`|`:setup_tips`|
  #
  class SystemChannelFlag < Flag
    @bits = {
      member_join: 0,
      server_boost: 1,
      setup_tips: 2,
    }.freeze
  end

  #
  # Represents a welcome screen.
  #
  class WelcomeScreen < DiscordModel
    # @return [String] The description of the welcome screen.
    attr_reader :description
    # @return [Array<Discorb::WelcomeScreen::Channel>] The channels to display the welcome screen.
    attr_reader :channels
    # @return [Discorb::Guild] The guild the welcome screen belongs to.
    attr_reader :guild

    # @!visibility private
    def initialize(client, guild, data)
      @client = client
      @description = data[:description]
      @guild = guild
      @channels = data[:channels].map { |c| WelcomeScreen::Channel.new(client, c, nil) }
    end

    #
    # Represents a channel to display the welcome screen.
    #
    class Channel < DiscordModel
      # @return [String] The channel's name.
      attr_reader :description

      # @!attribute [r] emoji
      #   @return [Discorb::Emoji] The emoji to display.
      # @!attribute [r] channel
      #   @macro client_cache
      #   @return [Discorb::Channel] The channel to display the welcome screen.

      #
      # Initialize a new welcome screen channel.
      #
      # @param [Discorb::TextChannel] channel The channel to display the welcome screen.
      # @param [String] description The channel's name.
      # @param [Discorb::Emoji] emoji The emoji to display.
      #
      def initialize(channel, description, emoji)
        if description.is_a?(Hash)
          @screen = channel
          data = description
          @channel_id = Snowflake.new(data[:channel_id])
          @description = data[:description]
          @emoji_id = Snowflake.new(data[:emoji_id])
          @emoji_name = data[:emoji_name]
        else
          @channel_id = channel.id
          @description = description
          if emoji.is_a?(UnicodeEmoji)
            @emoji_id = nil
            @emoji_name = emoji.value
          else
            @emoji_id = emoji.id
            @emoji_name = emoji.name
          end
        end
      end

      #
      # Converts the channel to a hash.
      #
      # @return [Hash] The hash.
      # @see https://discord.com/developers/docs/resources/guild#welcome-screen-object
      #
      def to_hash
        {
          channel_id: @channel_id,
          description: @description,
          emoji_id: @emoji_id,
          emoji_name: @emoji_name,
        }
      end

      def channel
        @screen.guild.channels[@channel_id]
      end

      def emoji
        if @emoji_id.nil?
          UnicodeEmoji.new(@emoji_name)
        else
          @screen.guild.emojis[@emoji_id]
        end
      end

      #
      # Edits the welcome screen.
      # @macro async
      # @macro http
      # @macro edit
      #
      # @param [Boolean] enabled Whether the welcome screen is enabled.
      # @param [Array<Discorb::WelcomeScreen::Channel>] channels The channels to display the welcome screen.
      # @param [String] description The description of the welcome screen.
      # @param [String] reason The reason for editing the welcome screen.
      #
      def edit(enabled: :unset, channels: :unset, description: :unset, reason: nil)
        Async do
          payload = {}
          payload[:enabled] = enabled unless enabled == :unset
          payload[:welcome_channels] = channels.map(&:to_hash) unless channels == :unset
          payload[:description] = description unless description == :unset
          @client.http.patch("/guilds/#{@guild.id}/welcome-screen", payload, audit_log_reason: reason).wait
        end
      end
    end
  end
end
