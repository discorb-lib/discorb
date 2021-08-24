# frozen_string_literal: true

module Discorb
  class GuildTemplate < DiscordModel
    attr_reader :code, :name, :description, :usage_count, :creator, :created_at, :updated_at, :source_guild_id, :serialized_source_guild, :is_dirty
    alias content serialized_source_guild
    alias dirty? is_dirty

    def initialize(client, data)
      @client = client
      _set_data(data)
    end

    def source_guild
      @client.guilds[@source_guild_id]
    end

    def edit(name = nil, description = :unset)
      Async do
        payload = {}
        payload[:name] = name if name
        payload[:description] = description if description != :unset
        @client.internet.patch("/guilds/#{@source_guild_id}/templates/#{@code}", payload).wait
      end
    end

    alias modify edit

    def update
      Async do
        _resp, data = @client.internet.put("/guilds/#{@source_guild_id}/templates/#{@code}").wait
        _set_data(data)
      end
    end

    def delete!
      Async do
        @client.internet.delete("/guilds/#{@source_guild_id}/templates/#{@code}").wait
      end
    end

    class TemplateGuild < DiscordModel
      attr_reader :name, :description, :region, :verification_level, :default_message_notifications,
                  :explicit_content_filter, :preferred_locale, :afk_timeout, :roles, :channels, :system_channel_flags

      def initialize(data)
        @name = data[:name]
        @description = data[:description]
        @region = data[:region]
        @verification_level = Discorb::Guild.mfa_levels[data[:verification_level]]
        @default_message_notifications = Discorb::Guild.notification_levels[data[:default_message_notifications]]
        @explicit_content_filter = Discorb::Guild.explicit_content_filter[data[:explicit_content_filter]]
        @preferred_locale = data[:preferred_locale]
        @afk_timeout = data[:afk_timeout]
        @roles = data[:roles].map { |r| Role.new(r) }
        @channels = data[:channels].map { |c| Channel.new(c) }
        @system_channel_flags = Discorb::SystemChannelFlag.new(data[:system_channel_flags])
      end

      class Role < DiscordModel
        attr_reader :name, :permissions, :color

        def initialize(data)
          @name = data[:name]
          @permissions = Permission.new(data[:permissions])
          @color = Color.new(data[:color])
          @hoist = data[:hoist]
          @mentionable = data[:mentionable]
        end
      end

      class Channel < DiscordModel
        attr_reader :name, :position, :topic, :bitrate, :user_limit, :nsfw, :rate_limit_per_user, :parent_id, :permission_overwrites, :type

        def initialize(data)
          @name = data[:name]
          @position = data[:position]
          @topic = data[:topic]
          @bitrate = data[:bitrate]
          @user_limit = data[:user_limit]
          @nsfw = data[:nsfw]
          @rate_limit_per_user = data[:rate_limit_per_user]
          @parent_id = data[:parent_id]
          @permission_overwrites = data[:permission_overwrites].map do |ow|
            [Snowflake.new(ow[:id]), PermissionOverwrite.new(ow[:allow], ow[:deny])]
          end.to_h
          @type = Discorb::Channel.descendants.find { |c| c.channel_type == data[:type] }
        end
      end
    end

    private

    def _set_data(data)
      @code = data[:code]
      @name = data[:name]
      @description = data[:description]
      @usage_count = data[:usage_count]
      @creator_id = Snowflake.new(data[:creator_id])
      @creator = @client.users[@creator_id] || User.new(@client, data[:creator])
      @created_at = Time.iso8601(data[:created_at])
      @updated_at = Time.iso8601(data[:updated_at])
      @source_guild_id = Snowflake.new(data[:source_guild_id])
      @serialized_source_guild = data[:serialized_source_guild]
      @is_dirty = data[:is_dirty]
    end
  end
end
