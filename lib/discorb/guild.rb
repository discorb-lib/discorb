# frozen_string_literal: true

require 'time'
require_relative 'flag'
require_relative 'dictionary'
require_relative 'color'
require_relative 'member'
require_relative 'channel'
require_relative 'permission'

module Discorb
  class SystemChannelFlag < Flag
    @bits = {
      member_join: 0,
      server_boost: 1,
      setup_tips: 2
    }
  end

  class Guild < DiscordModel
    attr_reader :id, :name, :splash, :discovery_splash, :owner_id, :permissions, :region, :afk_timeout, :roles, :emojis,
                :features, :mfa_level, :application_id, :system_channel_flags, :joined_at, :large,
                :unavailable, :member_count, :icon, :voice_states, :members, :channels, :threads,
                :presences, :max_presences, :max_members, :vanity_url_code, :description, :banner, :premium_tier,
                :premium_subscription_count, :preferred_locale, :public_updates_channel_id, :max_video_channel_users,
                :approximate_member_count, :approximate_presence_count, :welcome_screen, :nsfw_level, :stage_instances

    @mfa_levels = %i[none low medium high very_high]
    @nsfw_levels = %i[default explicit safe age_restricted]

    def initialize(client, data, is_create_event)
      @client = client
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

    def leave
      Async do
        @client.internet.delete("/users/@me/guilds/#{@id}", nil).wait
        @client.guilds.delete(@id)
      end
    end

    class << self
      attr_reader :nsfw_levels, :mfa_levels
    end

    def _set_data(data, is_create_event)
      @id = Snowflake.new(data[:id])
      if data[:unavailable]
        @unavailable = true
        return
      end
      @client.guilds[@id] = self
      @icon = data[:icon].nil? ? nil : Asset.new(self, data[:icon])
      @unavailable = false
      @name = data[:name]
      @members = Discorb::Cache.new
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
      @roles = Cache.new
      data[:roles].each do |r|
        Role.new(@client, self, r)
      end
      @emojis = Cache.new
      data[:emojis].map do |e|
        CustomEmoji.new(@client, self, e)
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

      @joined_at = Time.iso8601(data[:joined_at])
      @large = data[:large]
      @member_count = data[:member_count]
      @channels = Cache.new(data[:channels].map { |c| Channel.make_channel(@client, c) }.map { |c| [c.id, c] }.to_h)

      @voice_states = nil # TODO: Array<Discorb::VoiceState>
      @threads = data[:threads] ? data[:threads].map { |t| Channel.make_channel(@client, t) } : []
      @presences = nil # TODO: Array<Discorb::Presence>
      @max_presences = data[:max_presences]
      @stage_instances = nil # TODO: Array<Discorb::StageInstance>
    end
  end

  class Role < DiscordModel
    attr_reader :id, :name, :color, :permissions, :position

    include Comparable
    def initialize(client, guild, data)
      @client = client
      @guild = guild
      _set_data(data)
    end

    def <=>(other)
      @position <=> other.position
    end

    def to_s
      "<@&#{@id}>"
    end

    def color?
      @color != 0
    end

    def hoist?
      @hoist
    end

    def managed?
      @managed
    end

    def mentionable?
      @mentionable
    end

    def update!
      Async do
        _resp, data = @client.internet.get("/guilds/#{@guild_id}/roles").wait
        _set_data(data.find { |r| r[:id] == @id })
      end
    end

    def inspect
      "#<#{self.class} @#{@name} id=#{@id}>"
    end

    class Tag
      attr_reader :bot_id, :integration_id, :premium_subscriber

      def initialize(data)
        @bot_id = Snowflake.new(data[:bot_id])
        @integration_id = Snowflake.new(data[:bot_id])
        @premium_subscriber = Snowflake.new(data[:bot_id])
      end

      def bot?
        !@bot_id.nil?
      end

      def integration?
        !@integration_id.nil?
      end

      def premium_subscriber?
        !!@premium_subscriber
      end
    end

    def _set_data(data)
      @id = Snowflake.new(data[:id])
      @name = data[:name]
      @color = Color.new(data[:color])
      @hoist = data[:hoist]
      @position = data[:position]
      @permissions = Permission.new(data[:permissions].to_i)
      @managed = data[:managed]
      @mentionable = data[:mentionable]
      @tags = data[:tags] || {}
      @guild.roles[@id] = self
    end
  end

  class WelcomeScreen < DiscordModel
    attr_reader :description, :channels, :guild

    def initialize(client, guild, data)
      @client = client
      @description = data[:description]
      @guild = guild
    end

    class Channel
      attr_reader :description

      def initialize(screen, data)
        @screen = screen
        @channel_id = Snowflake.new(data[:channel_id])
        @description = data[:description]
        @emoji_id = Snowflake.new(data[:emoji_id])
        @emoji_name = data[:emoji_name]
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
    end
  end
end
