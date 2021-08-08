# frozen_string_literal: true

require_relative 'common'
require_relative 'flag'
require_relative 'error'
require_relative 'asset'

module Discorb
  class User < DiscordModel
    attr_reader :client, :verified, :username, :mfa_enabled, :id, :flag, :email, :discriminator, :avatar

    def initialize(client, data)
      @client = client
      @data = {}
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

    def inspect
      "#<#{self.class} #{self}>"
    end

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
        discord_certified_moderator: 18
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
      @data.update(data)
    end
  end

  class ClientUser < User
    def edit(name: false, avatar: false)
      Async do
        payload = {}
        payload[:username] = name if name
        if avatar.nil?
          payload[:avatar] = nil
        elsif avatar
          payload[:avatar] = avatar.to_s
        end
        @client.internet.patch('/users/@me', payload).wait
        self
      end
    end
  end
end
