require "overloader"
require_relative "common"
require_relative "flag"
require_relative "error"
require_relative "avatar"

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
      discord_certified_moderator: 18,
    }
  end

  class User < DiscordModel
    attr_reader :client, :verified, :username, :mfa_enabled, :id, :flag, :email, :discriminator, :avatar

    def initialize(client, data)
      @client = client
      set_data(data)
    end

    def update!()
      Async do
        _, data = @client.get("/users/#{@id}").wait
        set_data(data)
      end
    end

    def bot?
      @bot
    end

    def to_s
      @username + "#" + @discriminator.to_s
    end

    private

    def set_data(data)
      @username = data[:username]
      @verified = data[:verified]
      @id = data[:id].to_i
      @flag = UserFlag.new(data[:public_flags])
      @email = data[:email]
      @discriminator = data[:discriminator].to_i
      @avatar = Avatar.new(self, data[:avatar])
      @bot = data[:bot]
      @raw_data = data
      @client.users[@id] = self
    end
  end

  class ClientUser < User
  end
end
