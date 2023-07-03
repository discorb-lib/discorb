# frozen_string_literal: true

module Discorb
  #
  # Represents a user of discord.
  #
  class User < DiscordModel
    # @return [Boolean] Whether the user is verified.
    attr_reader :verified
    # @return [String] The user's username. ("sevenc_nanashi" for new users, "Nanashi." for old users.)
    attr_reader :username
    alias name username
    # @return [Discorb::Snowflake] The user's ID.
    attr_reader :id
    # @return [Discorb::User::Flag] The user's flags.
    attr_reader :flag
    # @return [String] The user's discriminator. ("0" for new users, "7740" for old users.)
    # @deprecated This will be removed in the future because of discord.
    attr_reader :discriminator
    # @return [String] The user's global name. ("Nanashi." for new users, old users have no global name.)
    attr_reader :global_name
    # @return [Discorb::Asset, Discorb::DefaultAvatar] The user's avatar.
    attr_reader :avatar
    # @return [Boolean] Whether the user is a bot.
    attr_reader :bot
    alias bot? bot
    # @return [Time] The time the user was created.
    attr_reader :created_at

    include Discorb::Messageable

    # @!attribute [r] mention
    #   @return [String] The user's mention.

    #
    # Initializes a new user.
    # @private
    #
    # @param [Discorb::Client] client The client.
    # @param [Hash] data The user data.
    #
    def initialize(client, data)
      @client = client
      @data = {}
      @dm_channel_id = nil
      _set_data(data)
    end

    #
    # Format the user as `Global name (@Username)` or `Username#Discriminator` style.
    #
    # @return [String] The formatted username.
    #
    def to_s
      if @discriminator == "0"
        "#{@global_name} (@#{@username})"
      else
        "#{@username}##{@discriminator}"
      end
    end

    def mention
      "<@#{@id}>"
    end

    alias to_s_user to_s

    def inspect
      "#<#{self.class} #{self}>"
    end

    #
    # Whether the user is a owner of the client.
    # @async
    #
    # @param [Boolean] strict Whether don't allow if the user is a member of the team.
    #
    # @return [Async::Task<Boolean>] Whether the user is a owner of the client.
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

    #
    # Returns the dm channel id of the user.
    # @private
    #
    # @return [Async::Task<Discorb::Snowflake>] A task that resolves to the channel id.
    #
    def channel_id
      Async do
        next @dm_channel_id if @dm_channel_id

        _resp, dm_channel =
          @client
            .http
            .request(
              Route.new("/users/@me/channels", "//users/@me/channels", :post),
              { recipient_id: @id }
            )
            .wait
        @dm_channel_id = dm_channel[:id]
        @dm_channel_id
      end
    end

    #
    # Represents the user's flags.
    # ## Flag fields
    # |`1 << 0`|`:staff`|
    # |`1 << 1`|`:partner`|
    # |`1 << 2`|`:hypesquad`|
    # |`1 << 3`|`:bug_hunter_level_1`|
    # |`1 << 6`|`:hypesquad_online_house_1`|
    # |`1 << 7`|`:hypesquad_online_house_2`|
    # |`1 << 8`|`:hypesquad_online_house_3`|
    # |`1 << 9`|`:premium_early_supporter`|
    # |`1 << 10`|`:team_psuedo_user`|
    # |`1 << 14`|`:bug_hunter_level_2`|
    # |`1 << 16`|`:verified_bot`|
    # |`1 << 17`|`:verified_developer`|
    # |`1 << 18`|`:certified_moderator`|
    # |`1 << 19`|`:bot_http_interactions`|
    #
    class Flag < Discorb::Flag
      @bits = {
        staff: 0,
        partner: 1,
        hypesquad: 2,
        bug_hunter_level_1: 3,
        hypesquad_online_house_1: 6,
        hypesquad_online_house_2: 7,
        hypesquad_online_house_3: 8,
        premium_early_supporter: 9,
        team_psuedo_user: 10,
        bug_hunter_level_2: 14,
        verified_bot: 16,
        verified_developer: 17,
        certified_moderator: 18,
        bot_http_interactions: 19
      }.freeze
    end

    private

    def _set_data(data)
      @username = data[:username]
      @global_name = data[:global_name]
      @verified = data[:verified]
      @id = Snowflake.new(data[:id])
      @flag = User::Flag.new(data[:public_flags] | (data[:flags] || 0))
      @discriminator = data[:discriminator]
      @avatar =
        (
          if data[:avatar]
            Asset.new(self, data[:avatar])
          else
            DefaultAvatar.new(data[:discriminator])
          end
        )
      @bot = data[:bot] || false
      @raw_data = data
      @client.users[@id] = self unless data[:no_cache]
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
    # @async
    # @macro edit
    #
    # @param [String] name The new username.
    # @param [Discorb::Image] avatar The new avatar.
    #
    # @return [Async::Task<void>] The task.
    #
    def edit(name: Discorb::Unset, avatar: Discorb::Unset)
      Async do
        payload = {}
        payload[:username] = name unless name == Discorb::Unset
        if avatar == Discorb::Unset
          # Nothing
        elsif avatar.nil?
          payload[:avatar] = nil
        else
          payload[:avatar] = avatar.to_s
        end
        @client
          .http
          .request(Route.new("/users/@me", "//users/@me", :patch), payload)
          .wait
        self
      end
    end
  end
end
