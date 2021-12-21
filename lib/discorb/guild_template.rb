# frozen_string_literal: true

module Discorb
  #
  # Represents a guild template.
  #
  class GuildTemplate < DiscordModel
    # @return [String] The code of the template.
    attr_reader :code
    # @return [String] The name of the template.
    attr_reader :name
    # @return [String] The description of the template.
    attr_reader :description
    # @return [Integer] The number of times this template has been used.
    attr_reader :usage_count
    # @return [Discorb::User] The user who created this template.
    attr_reader :creator
    # @return [Time] The time this template was created.
    attr_reader :created_at
    # @return [Time] The time this template was last updated.
    attr_reader :updated_at
    # @return [Discorb::Guild] The guild where the template was created.
    attr_reader :source_guild_id
    # @return [Discorb::GuildTemplate::TemplateGuild] The guild where the template was created.
    attr_reader :serialized_source_guild
    alias content serialized_source_guild
    # @return [Boolean] Whether this template is dirty.
    attr_reader :is_dirty
    alias dirty? is_dirty

    # @!attribute [r] source_guild
    #   @macro client_cache
    #   @return [Discorb::Guild] The guild this template is based on.
    #   @return [nil] Client wasn't able to find the guild this template is based on.

    # @private
    def initialize(client, data)
      @client = client
      _set_data(data)
    end

    def source_guild
      @client.guilds[@source_guild_id]
    end

    #
    # Edit the template.
    # @!async
    # @macro edit
    #
    # @param [String] name The new name of the template.
    # @param [String] description The new description of the template.
    #
    # @return [Async::Task<void>] The task.
    #
    def edit(name = nil, description = :unset)
      Async do
        payload = {}
        payload[:name] = name if name
        payload[:description] = description if description != :unset
        @client.http.patch("/guilds/#{@source_guild_id}/templates/#{@code}", payload).wait
      end
    end

    alias modify edit

    #
    # Update the template.
    # @!async
    #
    # @return [Async::Task<void>] The task.
    #
    def update
      Async do
        _resp, data = @client.http.put("/guilds/#{@source_guild_id}/templates/#{@code}").wait
        _set_data(data)
      end
    end

    #
    # Delete the template.
    # @!async
    #
    # @return [Async::Task<void>] The task.
    #
    def delete!
      Async do
        @client.http.delete("/guilds/#{@source_guild_id}/templates/#{@code}").wait
      end
    end

    alias destroy! delete!

    #
    # Represents a guild in guild template.
    #
    class TemplateGuild < DiscordModel
      # @return [String] The name of the guild.
      attr_reader :name
      # @return [Integer] The AFK timeout of the guild.
      attr_reader :afk_timeout
      # @return [Discorb::Dictionary{Discorb::Snowflake => Discorb::Role}] A dictionary of roles in the guild.
      attr_reader :roles
      # @return [Discorb::SystemChannelFlag] The flag for the system channel.
      attr_reader :system_channel_flags
      # @return [Discorb::Dictionary{Discorb::Snowflake => Discorb::GuildChannel}] A dictionary of channels in the guild.
      attr_reader :channels
      # @return [String] The description of the guild.
      attr_reader :description
      # @return [Symbol] The preffered language of the guild.
      # @note This modifies the language code, `-` will be replaced with `_`.
      attr_reader :preferred_locale
      # @return [:none, :low, :medium, :high, :very_high] The verification level of the guild.
      attr_reader :verification_level
      # @return [:all_messages, :only_mentions] The default message notification level of the guild.
      attr_reader :default_message_notifications
      # @return [:disabled_in_text, :members_without_roles, :all_members] The explict content filter level of the guild.
      attr_reader :explicit_content_filter
      # @return [Boolean] Whether the guild enabled the widget.
      attr_reader :widget_enabled
      alias widget_enabled? widget_enabled

      # @private
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

      #
      # Represents a role in guild template.
      #
      class Role < DiscordModel
        # @return [String] The name of the role.
        attr_reader :name
        # @return [Discorb::Permission] The permissions of the role.
        attr_reader :permissions
        # @return [Discorb::Color] The color of the role.
        attr_reader :color

        # @private
        def initialize(data)
          @name = data[:name]
          @permissions = Permission.new(data[:permissions])
          @color = Color.new(data[:color])
          @hoist = data[:hoist]
          @mentionable = data[:mentionable]
        end
      end

      #
      # Represents a channel in guild template.
      #
      class Channel < DiscordModel
        # @return [String] The name of the channel.
        attr_reader :name
        # @return [Integer] The position of the channel.
        attr_reader :position
        # @return [String] The type of the channel.
        attr_reader :topic
        # @return [Integer] The bitrate of the channel.
        attr_reader :bitrate
        # @return [Integer] The user limit of the channel.
        attr_reader :user_limit
        # @return [Boolean] Whether the channel is nsfw.
        attr_reader :nsfw
        # @return [Integer] The rate limit of the channel.
        attr_reader :rate_limit_per_user
        # @return [Class] The class of the channel.
        attr_reader :type

        # @private
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
