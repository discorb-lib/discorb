require_relative "flag"

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

  class User
    attr_reader :client, :verified, :username, :mfa_enabled, :id, :flag, :email, :discriminator, :avatar

    def initialize(client, data)
      @client = client
      @username = data[:username]
      @verified = data[:verified]
      @id = data[:id].to_i
      @flag = UserFlag.new(data[:flags])
      @email = data[:email]
      @discriminator = data[:discriminator].to_i
      @avatar = data[:avatar]
      @bot = data[:bot]
      @raw_data = data
    end

    def bot?
      @bot
    end

    def to_s
      @username + "#" + @discriminator.to_s
    end
  end
end
