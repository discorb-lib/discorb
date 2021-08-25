# frozen_string_literal: true

module Discorb
  class Integration < DiscordModel
    attr_reader :id, :type, :enabled, :syncing, :role_id, :enable_emoticons, :expire_behavior,
                :expire_grace_period, :user, :account, :subscriber_count, :revoked, :application

    @expire_behavior = {
      0 => :remove_role,
      1 => :kick,
    }

    def initialize(client, data, guild_id, no_cache: false)
      @client = client
      @data = data
      @guild_id = guild_id
      _set_data(data)
      guild.integrations[@id] = self unless no_cache
    end

    def guild
      @client.guilds[@guild_id]
    end

    def delete!(reason: nil)
      Async do
        @client.internet.delete("/guilds/#{@guild}/integrations/#{@id}", reason: reason).wait
      end
    end

    alias destroy! delete!

    private

    def _set_data(data)
      @id = Snowflake.new(data[:id])
      @type = data[:type].to_sym
      @enabled = data[:enabled]
      @syncing = data[:syncing]
      @role_id = Snowflake.new(data[:role_id])
      @enable_emoticons = data[:enable_emoticons]
      @expire_behavior = self.class.expire_behavior[data[:expire_behavior]]
      @expire_grace_period = data[:expire_grace_period]
      @user = client.users[data[:user].to_i]
      @account = Account.new(data[:account])
      @subscriber_count = data[:subscriber_count]
      @revoked = data[:revoked]
      @application = Application.new(@client, data[:application])
    end

    class << self
      attr_reader :expire_behavior
    end

    class Account < DiscordModel
      attr_reader :id, :name

      def initialize(data)
        @id = data[:id]
        @name = data[:name]
      end
    end
  end
end
