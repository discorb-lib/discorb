# frozen_string_literal: true

module Discorb
  #
  # Represents a user of discord.
  #
  class User < DiscordModel
    # @return [Boolean] Whether the user is verified.
    attr_reader :verified
    # @return [String] The user's username.
    attr_reader :username
    alias name username
    # @return [Discorb::Snowflake] The user's ID.
    attr_reader :id
    # @return [Discorb::User::Flag] The user's flags.
    attr_reader :flag
    # @return [String] The user's discriminator.
    attr_reader :discriminator
    # @return [Discorb::Asset] The user's avatar.
    attr_reader :avatar
    # @return [Boolean] Whether the user is a bot.
    attr_reader :bot
    alias bot? bot
    # @return [Time] The time the user was created.
    attr_reader :created_at

    include Discorb::Messageable

    # @!visibility private
    def initialize(client, data)
      @client = client
      @data = {}
      @dm_channel_id = nil
      _set_data(data)
    end

    #
    # Format the user as `Username#Discriminator` style.
    #
    # @return [String] The formatted username.
    #
    def to_s
      "#{@username}##{@discriminator}"
    end

    def inspect
      "#<#{self.class} #{self}>"
    end

    #
    # Whether the user is a owner of the client.
    # @macro async
    # @macro http
    #
    # @param [Boolean] strict Whether don't allow if the user is a member of the team.
    #
    # @return [Boolean] Whether the user is a owner of the client.
    #
    def bot_owner?(strict: false)
      Async do
        app = @client.fetch_application.wait
        if app.team.nil?
          app.owner == self
        elsif strict
          app.team.owner == self
        else
          app.team.members.any? { |m| m.user == self }
        end
      end
    end

    alias app_owner? bot_owner?

    # @!visibility private
    def base_url
      Async do
        next @dm_channel_id if @dm_channel_id

        dm_channel = @client.http.post("/users/#{@id}/channels", { recipient_id: @client.user.id }).wait
        @dm_channel_id = dm_channel[:id]
        "/channels/#{@dm_channel_id}"
      end
    end

    #
    # Represents the user's flags.
    # ## Flag fields
    # |`1 << 0`|`:discord_employee`|
    # |`1 << 1`|`:partnered_server_owner`|
    # |`1 << 2`|`:hypesquad_events`|
    # |`1 << 3`|`:bug_hunter_level_1`|
    # |`1 << 6`|`:house_bravery`|
    # |`1 << 7`|`:house_brilliance`|
    # |`1 << 8`|`:house_balance`|
    # |`1 << 9`|`:early_supporter`|
    # |`1 << 10`|`:team_user`|
    # |`1 << 14`|`:bug_hunter_level_2`|
    # |`1 << 16`|`:verified_bot`|
    # |`1 << 17`|`:early_verified_bot_developer`|
    # |`1 << 18`|`:discord_certified_moderator`|
    #
    class Flag < Discorb::Flag
      @bits = {
        discord_employee: 0,
        partnered_server_owner: 1,
        hypesquad_events: 2,
        bug_hunter_level_1: 3,
        house_bravery: 6,
        house_brilliance: 7,
        house_balance: 8,
        early_supporter: 9,
        team_user: 10,
        bug_hunter_level_2: 14,
        verified_bot: 16,
        early_verified_bot_developer: 17,
        discord_certified_moderator: 18,
      }.freeze
    end

    private

    def _set_data(data)
      @username = data[:username]
      @verified = data[:verified]
      @id = Snowflake.new(data[:id])
      @flag = User::Flag.new(data[:public_flags] | (data[:flags] || 0))
      @discriminator = data[:discriminator]
      @avatar = Asset.new(self, data[:avatar])
      @bot = data[:bot]
      @raw_data = data
      @client.users[@id] = self if !data[:no_cache] && data.is_a?(User)
      @created_at = @id.timestamp
      @data.update(data)
    end
  end

  #
  # Represents a client user.
  #
  class ClientUser < User
    #
    # Edit the client user.
    # @macro async
    # @macro http
    # @macro edit
    #
    # @param [String] name The new username.
    # @param [Discorb::Image] avatar The new avatar.
    #
    def edit(name: :unset, avatar: :unset)
      Async do
        payload = {}
        payload[:username] = name unless name == :unset
        if avatar == :unset
          # Nothing
        elsif avatar.nil?
          payload[:avatar] = nil
        else
          payload[:avatar] = avatar.to_s
        end
        @client.http.patch("/users/@me", payload).wait
        self
      end
    end
  end
end
