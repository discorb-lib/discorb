# frozen_string_literal: true

require "time"
require_relative "flag"
require_relative "member"
require_relative "channel"

module Discorb
  class SystemChannelFlag < Flag
    @bits = {
      member_join: 0,
      server_boost: 1,
      setup_tips: 2,
    }
  end

  class Guild < DiscordModel
    attr_reader :id, :name, :splash, :discovery_splash, :owner_id, :permissions, :region, :afk_timeout, :roles, :emojis, :features, :mfa_level,
                :application_id, :system_channel_flags, :joined_at, :large, :unavailable, :member_count,
                :voice_states, :members, :channels, :threads, :presences, :max_presences, :max_members, :vanity_url_code,
                :description, :banner, :premium_tier, :premium_subscription_count, :preferred_locale, :public_updates_channel_id, :max_video_channel_users,
                :approximate_member_count, :approximate_presence_count, :welcome_screen, :nsfw_level, :stage_instances

    @mfa_levels = %i[none low medium high very_high]
    @nsfw_levels = %i[default explicit safe age_restricted]

    def initialize(client, data, is_create_event)
      @client = client
      _set_data(data, is_create_event)
    end

    def update!
      Async do
        _, data = @client.get("/users/#{@id}").wait
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

    private

    def _set_data(data, is_create_event)
      @id = Snowflake.new(data[:id])
      if data[:unavailable]
        @unavailable = true
        return
      end
      @unavailable = false
      @name = data[:name]
      @members = data[:members].map { |m| Member.new(@client, m[:user], m) }
      @splash = data[:splash]
      @discovery_splash = data[:discovery_splash]
      @owner_id = data[:owner_id]
      @permissions = nil # TODO: Discorb::Permissions
      @region = data[:region]
      @afk_channel_id = data[:afk_channel_id]
      @afk_timeout = data[:afk_timeout]
      @widget_enabled = data[:widget_enabled]
      @widget_channel_id = data[:widget_channel_id]
      @roles = nil # TODO: Array<Discorb::Role>
      @emojis = data[:emojis].map { |e| CustomEmoji.new(@client, e) }
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
      @welcome_screen = nil # TODO: Discorb::WelcomeScreen
      @nsfw_level = self.class.nsfw_levels[data[:nsfw_level]]

      if is_create_event
        @joined_at = Time.iso8601(data[:joined_at])
        @large = data[:large]
        @member_count = data[:member_count]
        @channels = data[:channels].map { |c| Discorb.make_channel(@client, c) }
        @voice_states = nil # TODO: Array<Discorb::VoiceState>
        @threads = nil # TODO: Array<Discorb::Thread>
        @presences = nil # TODO: Array<Discorb::Presence>
        @max_presences = data[:max_presences]
        @stage_instances = nil # TODO: Array<Discorb::StageInstance>
      end

      @client.guilds[@id] = self
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

    class << self
      def nsfw_levels
        @nsfw_levels
      end

      def mfa_levels
        @mfa_levels
      end
    end
  end
end
