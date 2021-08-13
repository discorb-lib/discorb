# frozen_string_literal: true

require_relative 'flag'
require_relative 'dictionary'
require_relative 'color'
require_relative 'member'
require_relative 'channel'
require_relative 'permission'
require_relative 'role'
require_relative 'voice_state'

module Discorb
  class SystemChannelFlag < Flag
    @bits = {
      member_join: 0,
      server_boost: 1,
      setup_tips: 2
    }.freeze
  end

  class Guild < DiscordModel
    attr_reader :id, :name, :splash, :discovery_splash, :owner_id, :permissions, :region, :afk_timeout, :roles, :emojis,
                :features, :mfa_level, :application_id, :system_channel_flags, :joined_at, :large,
                :unavailable, :member_count, :icon, :voice_states, :members, :channels, :threads,
                :presences, :max_presences, :max_members, :vanity_url_code, :description, :banner, :premium_tier,
                :premium_subscription_count, :preferred_locale, :public_updates_channel_id, :max_video_channel_users,
                :approximate_member_count, :approximate_presence_count, :welcome_screen, :nsfw_level, :stage_instances, :integrations

    @mfa_levels = %i[none low medium high very_high].freeze
    @nsfw_levels = %i[default explicit safe age_restricted].freeze

    def initialize(client, data, is_create_event)
      @client = client
      @data = {}
      _set_data(data, is_create_event)
    end

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

    def owner?
      @owner_id == @client.user.id
    end

    def large?
      @large
    end

    def widget_enabled?
      @widget_enabled
    end

    def available?
      !@unavailable
    end

    def me
      @members[@client.user.id]
    end

    def leave!
      Async do
        @client.internet.delete("/users/@me/guilds/#{@id}").wait
        @client.guilds.delete(@id)
      end
    end

    def fetch_emoji_list
      Async do
        _resp, data = @client.internet.get("/guilds/#{@id}/emojis").wait
        @emojis = Dictionary.new
        ids = @emojis.map(&:id).map(&:to_s)
        data.map do |e|
          next if ids.include?(e[:id])

          @emojis[e[:id]] = CustomEmoji.new(@client, self, e)
        end
      end
    end

    alias fetch_emojis fetch_emoji_list

    def fetch_emoji(id)
      _resp, data = @client.internet.get("/guilds/#{@id}/emojis/#{id}").wait
      @emojis[e[:id]] = CustomEmoji.new(@client, self, data)
    end

    def create_emoji(name, image, roles: [])
      _resp, data = @client.internet.post(
        "/guilds/#{@id}/emojis",
        {
          name: name,
          image: image.to_s,
          roles: roles.map { |r| Discorb::Utils.try(r, :id) }
        }
      ).wait
      @emojis[data[:id]] = CustomEmoji.new(@client, self, data)
    end

    def fetch_webhooks
      Async do
        _resp, data = @client.internet.get("/guilds/#{@id}/webhooks").wait
        data.map { |webhook| Webhook.new([@client, webhook]) }
      end
    end

    def fetch_audit_log
      Async do
        _resp, data = @client.internet.get("/guilds/#{@id}/audit-logs").wait
        AuditLog.new(@client, data, self)
      end
    end

    def fetch_channels
      Async do
        _resp, data = @client.internet.get("/guilds/#{@id}/channels").wait
        data.map { |c| Channel.make_channel(@client, c) }
      end
    end

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
              deny: overwrite.deny_value
            }
          end
        end
        payload[:parent_id] = parent.id if parent
        _resp, data = @client.internet.post(
          "/guilds/#{@id}/channels", payload, audit_log_reason: reason
        ).wait
        payload[:parent_id] = parent&.id
        Channel.make_channel(@client, data)
      end
    end

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
              deny: overwrite.deny_value
            }
          end
        end
        payload[:parent_id] = parent.id if parent
        _resp, data = @client.internet.post(
          "/guilds/#{@id}/channels", payload, audit_log_reason: reason
        ).wait
        payload[:parent_id] = parent&.id
        Channel.make_channel(@client, data)
      end
    end

    def create_category_channel(name, permission_overwrites: nil, parent: nil, reason: nil)
      Async do
        payload = { type: CategoryChannel.channel_type }
        payload[:name] = name
        if permission_overwrites
          payload[:permission_overwrites] = permission_overwrites.map do |target, overwrite|
            {
              type: target.is_a?(Role) ? 0 : 1,
              id: target.id,
              allow: overwrite.allow_value,
              deny: overwrite.deny_value
            }
          end
        end
        payload[:parent_id] = parent&.id
        _resp, data = @client.internet.post(
          "/guilds/#{@id}/channels", payload, audit_log_reason: reason
        ).wait
        Channel.make_channel(@client, data)
      end
    end

    alias create_category create_category_channel

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
              deny: overwrite.deny_value
            }
          end
        end
        payload[:parent_id] = parent&.id
        _resp, data = @client.internet.post(
          "/guilds/#{@id}/channels", payload, audit_log_reason: reason
        ).wait
        Channel.make_channel(@client, data)
      end
    end

    def create_news_channel(
      name, topic: nil, rate_limit_per_user: nil, slowmode: nil, position: nil, permission_overwrites: nil, parent: nil, reason: nil
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
              deny: overwrite.deny_value
            }
          end
        end
        payload[:parent_id] = parent&.id
        _resp, data = @client.internet.post(
          "/guilds/#{@id}/channels", payload, audit_log_reason: reason
        ).wait
        Channel.make_channel(@client, data)
      end
    end

    def fetch_active_threads
      Async do
        _resp, data = @client.internet.get("/guilds/#{@id}/threads/active").wait
        data[:threads].map { |t| Channel.make_thread(@client, t) }
      end
    end

    def fetch_member(id)
      Async do
        _resp, data = @client.internet.get("/guilds/#{@id}/members/#{id}").wait
        Member.new(@client, @id, data[:user], data)
      end
    end

    def fetch_members_named(name, limit: 1)
      Async do
        _resp, data = @client.internet.get("/guilds/#{@id}/members/search?#{URI.encode_www_form({ query: name, limit: limit })}").wait
        data.map { |d| Member.new(@client, @id, d[:user], d) }
      end
    end

    def fetch_member_named(...)
      Async do
        fetch_members_named(...).first
      end
    end

    def edit_nickname(nickname, reason: nil)
      Async do
        @client.internet.patch("/guilds/#{@id}/members/@me/nick", { nick: nickname }, audit_log_reason: reason).wait
      end
    end

    alias edit_nick edit_nickname
    alias modify_nickname edit_nickname
    alias modify_nick modify_nickname

    def kick_member(member, reason: nil)
      Async do
        @client.internet.delete("/guilds/#{@id}/members/#{member.id}", audit_log_reason: reason).wait
      end
    end

    def fetch_bans
      Async do
        _resp, data = @client.internet.get("/guilds/#{@id}/bans").wait
        data.map { |d| Ban.new(@client, self, d) }
      end
    end

    def fetch_ban(user)
      Async do
        _resp, data = @client.internet.get("/guilds/#{@id}/bans/#{user.id}").wait
      rescue Discorb::NotFoundError
        nil
      else
        Ban.new(@client, self, data)
      end
    end

    def banned?(user)
      Async do
        !fetch_ban(user).wait.nil?
      end
    end

    def ban_member(user, delete_message_days: 0, reason: nil)
      Async do
        _resp, data = @client.internet.post(
          "/guilds/#{@id}/bans", { user: user.id, delete_message_days: delete_message_days }, audit_log_reason: reason
        ).wait
        Ban.new(@client, self, data)
      end
    end

    def unban_user(user, reason: nil)
      Async do
        @client.internet.delete("/guilds/#{@id}/bans/#{user.id}", audit_log_reason: reason).wait
      end
    end

    def fetch_roles
      Async do
        _resp, data = @client.internet.get("/guilds/#{@id}/roles").wait
        data.map { |d| Role.new(@client, self, d) }
      end
    end

    def create_role(name = nil, color: nil, hoist: nil, mentionable: nil, reason: nil)
      Async do
        payload = {}
        payload[:name] = name if name
        payload[:color] = color.to_i if color
        payload[:hoist] = hoist if hoist
        payload[:mentionable] = mentionable if mentionable
        _resp, data = @client.internet.post(
          "/guilds/#{@id}/roles", payload, audit_log_reason: reason
        )
        Role.new(@client, self, data)
      end
    end

    def fetch_prune(days = 7, roles: [])
      Async do
        params = {
          days: days,
          include_roles: @id.to_s
        }
        param[:include_roles] = roles.map(&:id).map(&:to_s).join(';') if roles.any?
        _resp, data = @client.internet.get("/guilds/#{@id}/prune?#{URI.encode_www_form(params)}").wait
        data[:pruned]
      end
    end

    def prune(days = 7, roles: [], reason: nil)
      Async do
        _resp, data = @client.internet.post(
          "/guilds/#{@id}/prune", { days: days, roles: roles.map(&:id) }, audit_log_reason: reason
        ).wait
        data[:pruned]
      end
    end

    def fetch_voice_regions
      Async do
        _resp, data = @client.internet.get("/guilds/#{@id}/voice").wait
        data.map { |d| VoiceRegion.new(@client, d) }
      end
    end

    def fetch_invites
      Async do
        _resp, data = @client.internet.get("/guilds/#{@id}/invites").wait
        data.map { |d| Invite.new(@client, d) }
      end
    end

    def fetch_integrations
      Async do
        _resp, data = @client.internet.get("/guilds/#{@id}/integrations").wait
        data.map { |d| Integration.new(@client, d) }
      end
    end

    def fetch_widget
      Async do
        _resp, data = @client.internet.get("/guilds/#{@id}/widget").wait
        Widget.new(@client, @id, data)
      end
    end

    def fetch_vanity_invite
      Async do
        _resp, data = @client.internet.get("/guilds/#{@id}/vanity-url").wait
        VanityInvite.new(@client, self, data)
      end
    end

    def fetch_welcome_screen
      Async do
        _resp, data = @client.internet.get("/guilds/#{@id}/welcome-screen").wait
        WelcomeScreen.new(@client, self, data)
      end
    end

    def fetch_stickers
      Async do
        _resp, data = @client.internet.get("/guilds/#{@id}/stickers").wait
        data.map { |d| Sticker::GuildSticker.new(@client, d) }
      end
    end

    def fetch_sticker(id)
      Async do
        _resp, data = @client.internet.get("/guilds/#{@id}/stickers/#{id}").wait
        Sticker::GuildSticker.new(@client, data)
      end
    end

    class VanityInvite < DiscordModel
      attr_reader :code, :uses

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

    class Widget < DiscordModel
      attr_reader :guild_id, :channel_id

      def initialize(client, guild_id, data)
        @client = client
        @guild_id = guild_id
        @enabled = data[:enabled]
        @channel_id = data[:channel_id]
      end

      def channel
        @client.channels[@channel_id]
      end

      def enable?
        @enabled
      end

      def edit(enabled: nil, channel: nil, reason: nil)
        Async do
          payload = {}
          payload[:enabled] = enabled unless enabled.nil?
          payload[:channel_id] = channel.id if channel_id
          @client.internet.patch("/guilds/#{@guild_id}/widget", payload, audit_log_reason: reason).wait
        end
      end

      def json_url
        "#{Discorb::API_BASE_URL}/guilds/#{@guild_id}/widget.json"
      end

      def iframe(theme: 'dark', width: 350, height: 500)
        [
          %(<iframe src="https://canary.discord.com/widget?id=#{@guild_id}&theme=#{theme}" width="#{width}" height="#{height}"),
          %(allowtransparency="true" frameborder="0" sandbox="allow-popups allow-popups-to-escape-sandbox allow-same-origin allow-scripts"></iframe>)
        ].join
      end
    end

    class Ban < DiscordModel
      attr_reader :user, :reason

      def initialize(client, guild, data)
        @client = client
        @guild = guild
        @reason = data[:reason]
        @user = @client.users[data[:user][:id]] || User.new(@client, data[:user])
      end
    end

    class << self
      attr_reader :nsfw_levels, :mfa_levels

      def banner(guild_id, style: 'banner')
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
      @icon = data[:icon].nil? ? nil : Asset.new(self, data[:icon])
      @unavailable = false
      @name = data[:name]
      @members = Discorb::Dictionary.new
      data[:members].each do |m|
        Member.new(@client, @id, m[:user], m)
      end
      @splash = data[:splash]
      @discovery_splash = data[:discovery_splash]
      @owner_id = data[:owner_id]
      @permissions = Permission.new(data[:permissions].to_i)
      @region = data[:region]
      @afk_channel_id = data[:afk_channel_id]
      @afk_timeout = data[:afk_timeout]
      @widget_enabled = data[:widget_enabled]
      @widget_channel_id = data[:widget_channel_id]
      @integrations = Dictionary.new
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
      @system_channel_id = data[:system_channel_id]
      @system_channel_flag = SystemChannelFlag.new(0b111 - data[:system_channel_flags])
      @rules_channel_id = data[:rules_channel_id]
      @vanity_url_code = data[:vanity_url_code]
      @description = data[:description]
      @banner_hash = data[:banner]
      @premium_tier = data[:premium_tier]
      @premium_subscription_count = data[:premium_tier_count].to_i
      @preferred_locale = data[:preferred_locale]
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
      @voice_states = Dictionary.new(data[:voice_states].map { |v| [v[:user_id], VoiceState.new(@client, v.merge({ guild_id: @id }))] }.to_h)
      @threads = data[:threads] ? data[:threads].map { |t| Channel.make_channel(@client, t) } : []
      @presences = Dictionary.new(data[:presences].map { |pr| [pr[:user][:id], Presence.new(@client, pr)] }.to_h)
      @max_presences = data[:max_presences]
      @stage_instances = Dictionary.new(data[:stage_instances].map { |s| [s[:id], StageInstance.new(@client, s)] }.to_h)
      @data.update(data)
    end
  end

  class WelcomeScreen < DiscordModel
    attr_reader :description, :channels, :guild

    def initialize(client, guild, data)
      @client = client
      @description = data[:description]
      @guild = guild
      @channels = data[:channels].map { |c| WelcomeScreen::Channel.new(client, c, nil) }
    end

    class Channel < DiscordModel
      attr_reader :description

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

      def to_hash
        {
          channel_id: @channel_id,
          description: @description,
          emoji_id: @emoji_id,
          emoji_name: @emoji_name
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

      def edit(enabled: nil, channels: nil, description: nil, reason: nil)
        payload = {}
        payload[:enabled] = enabled unless enabled.nil?
        payload[:welcome_channels] = channels.map(&:to_hash) unless channels.nil?
        payload[:description] = description unless description.nil?
        @client.internet.patch("/guilds/#{@guild.id}/welcome-screen", payload, audit_log_reason: reason).wait
      end
    end
  end
end
