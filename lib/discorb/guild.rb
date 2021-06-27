require "time"
require_relative "flag"

module Discorb
  class SystemChannelFlag < Flag
    @bits = {
      member_join: 0,
      server_boost: 1,
      setup_tips: 2,
    }
  end

  class Guild < DiscorbModel
    attr_reader :id, :name, :splash, :discovery_splash, :owner_id, :permissions, :region, :afk_timeout, :roles, :emojis, :features, :mfa_level,
                :application_id, :system_channel_flags, :joined_at, :large, :unavailable, :member_count, :voice_states, :members, :channels, :threads, :presences, :max_presences, :max_members, :vanity_url_code, :description, :banner, :premium_tier, :premium_subscription_count, :preferred_locale, :public_updates_channel_id, :max_video_channel_users, :approximate_member_count, :approximate_presence_count, :welcome_screen, :nsfw_level, :stage_instances

    @@mfa_levels = [:none, :low, :medium, :high, :very_high]
    @@nsfw_levels = [:default, :explicit, :safe, :age_restricted]

    def initialize(client, data, is_create_event)
      @client = client
      set_data(data, is_create_event)
    end

    def update!()
      Async do
        _, data = @client.get("/users/#{@id}").wait
        set_data(data, false)
      end
    end

    private

    def set_data(data, is_create_event)
      @id = data[:id].to_i
      if data[:unavailable]
        @unavailable = true
        return
      end
      @unavailable = false
      @name = data[:name]
      @splash = data[:splash]
      @discovery_splash = data[:discovery_splash]
      @owner_id = data[:owner_id]
      @permissions = nil  # TODO: Discorb::Permissions
      @region = data[:region]
      @afk_channel_id = data[:afk_channel_id]
      @afk_channel = nil  # TODO: Discorb::Channel
      @afk_timeout = data[:afk_timeout]
      @widget_enabled = data[:widget_enabled]
      @widget_channel_id = data[:widget_channel_id]
      @roles = nil # TODO: Array<Discorb::Role>
      @emojis = nil # TODO: Array<Discorb::Emoji>
      @features = data[:features].map { |f| f.downcase.to_sym }
      @mfa_level = @@mfa_levels[data[:mfa_level]]
      @system_channel_id = data[:system_channel_id]
      @system_channel = nil # TODO: Discorb::Channel
      @system_channel_flag = SystemChannelFlag.new(0b111 - data[:system_channel_flags])
      @rules_channel_id = data[:rules_channel_id]
      @rules_channel = nil # TODO: Discorb::Channel
      @vanity_url_code = data[:vanity_url_code]
      @description = data[:description]
      @banner_hash = data[:banner]
      @premium_tier = data[:premium_tier]
      @premium_subscription_count = data[:premium_tier_count].to_i
      @preferred_locale = data[:preferred_locale]
      @public_updates_channel_id = data[:public_updates_channel_id]
      @public_updates_channel = nil # TODO: Discorb::Channel
      @max_video_channel_users = data[:max_video_channel_users]
      @approximate_member_count = data[:approximate_member_count]
      @approximate_presence_count = data[:approximate_presence_count]
      @welcome_screen = nil # TODO: Discorb::WelcomeScreen
      @nsfw_level = @@nsfw_levels[data[:nsfw_level]]

      if is_create_event
        @joined_at = Time.iso8601(data[:joined_at])
        @large = data[:large]
        @member_count = data[:member_count]
        @voice_states = nil # TODO: Array<Discorb::VoiceState>
        @channels = nil # TODO: Array<Discorb::GuildChannel>
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
      not @unavailable
    end
  end
end
