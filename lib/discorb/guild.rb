# frozen_string_literal: true

require 'time'
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
      @_data = {}
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
        Role.new(@client, self, r)
      end
      @emojis = Dictionary.new
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
      tmp_channels = data[:channels].map do |c|
        Channel.make_channel(@client, c.merge({ guild_id: @id }))
      end
      @channels = Dictionary.new(tmp_channels.map { |c| [c.id, c] }.to_h, sort: :position.to_proc)
      @voice_states = Dictionary.new(data[:voice_states].map { |v| [v[:user_id], VoiceState.new(@client, v.merge({ guild_id: @id }))] }.to_h)
      @threads = data[:threads] ? data[:threads].map { |t| Channel.make_channel(@client, t) } : []
      @presences = nil # TODO: Array<Discorb::Presence>
      @max_presences = data[:max_presences]
      @stage_instances = Dictionary.new(data[:stage_instances].map { |s| [s[:id], StageInstance.new(@client, s)] }.to_h)
      @_data.update(data)
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
