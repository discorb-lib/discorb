# frozen_string_literal: true

require 'overloader'
require_relative 'common'
require_relative 'flag'
require_relative 'error'
require_relative 'asset'

module Discorb
  class UserFlag < Flag
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
      discord_certified_moderator: 18
    }
  end

  class User < DiscordModel
    attr_reader :client, :verified, :username, :mfa_enabled, :id, :flag, :email, :discriminator, :avatar, :_data

    def initialize(client, data)
      @client = client
      @_data = {}
      _set_data(data)
    end

    def update!
      Async do
        _, data = @client.get("/users/#{@id}").wait
        _set_data(data)
      end
    end

    def name
      @username
    end

    def bot?
      @bot
    end

    def to_s
      "#{@username}##{@discriminator}"
    end

    def _set_data(data)
      @username = data[:username]
      @verified = data[:verified]
      @id = Snowflake.new(data[:id])
      @flag = UserFlag.new(data[:public_flags])
      @email = data[:email]
      @discriminator = data[:discriminator]
      @avatar = Asset.new(self, data[:avatar])
      @bot = data[:bot]
      @raw_data = data
      @client.users[@id] = self
      @_data.update(data)
    end
  end

  class ClientUser < User
  end
end
