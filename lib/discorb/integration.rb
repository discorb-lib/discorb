# frozen_string_literal: true

module Discorb
  #
  # Represents a integration.
  #
  class Integration < DiscordModel
    # @return [Discorb::Snowflake] The ID of the integration.
    attr_reader :id
    # @return [Symbol] The type of integration.
    attr_reader :type
    # @return [Boolean] Whether the integration is enabled.
    attr_reader :enabled
    alias enabled? enabled
    # @return [Boolean] Whether the integration is syncing.
    attr_reader :syncing
    alias syncing? syncing
    # @return [Boolean] Whether the integration is enabled emoticons.
    attr_reader :enable_emoticons
    alias enable_emoticons? enable_emoticons
    # @return [:remove_role, :kick] The behavior of the integration when it expires.
    attr_reader :expire_behavior
    # @return [Integer] The grace period of the integration.
    attr_reader :expire_grace_period
    # @return [Discorb::User] The user for the integration.
    attr_reader :user
    # @return [Discorb::Integration::Account] The account for the integration.
    attr_reader :account
    # @return [Integer] The number of subscribers for the integration.
    attr_reader :subscriber_count
    # @return [Boolean] Whether the integration is revoked.
    attr_reader :revoked
    alias revoked? revoked
    # @return [Discorb::Application] The application for the integration.
    attr_reader :application

    # @!attribute [r] guild
    #   @macro client_cache
    #   @return [Discorb::Guild] The guild this integration is in.

    @expire_behavior = {
      0 => :remove_role,
      1 => :kick,
    }

    # @private
    def initialize(client, data, guild_id, no_cache: false)
      @client = client
      @data = data
      @guild_id = guild_id
      _set_data(data)
    end

    def guild
      @client.guilds[@guild_id]
    end

    #
    # Delete the integration.
    # @async
    #
    # @param [String] reason The reason for deleting the integration.
    #
    # @return [Async::Task<void>] The task.
    #
    def delete!(reason: nil)
      Async do
        @client.http.delete("/guilds/#{@guild}/integrations/#{@id}", audit_log_reason: reason).wait
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
      @user = @client.users[data[:user][:id]] or Discorb::User.new(@client, data[:user])
      @account = Account.new(data[:account])
      @subscriber_count = data[:subscriber_count]
      @revoked = data[:revoked]
      @application = data[:application] and Application.new(@client, data[:application])
    end

    class << self
      # @private
      attr_reader :expire_behavior
    end

    #
    # Represents an account for an integration.
    #
    class Account < DiscordModel
      # @return [String] The ID of the account.
      attr_reader :id
      # @return [String] The name of the account.
      attr_reader :name

      # @private
      def initialize(data)
        @id = data[:id]
        @name = data[:name]
      end
    end

    #
    # Represents an application for an integration.
    #
    class Application < DiscordModel
      # @return [Discorb::Snowflake] The ID of the application.
      attr_reader :id
      # @return [String] The name of the application.
      attr_reader :name
      # @return [Asset] The icon of the application.
      # @return [nil] If the application has no icon.
      attr_reader :icon
      # @return [String] The description of the application.
      attr_reader :description
      # @return [String] The summary of the application.
      attr_reader :summary
      # @return [Discorb::User] The bot user associated with the application.
      # @return [nil] If the application has no bot user.
      attr_reader :bot

      # @private
      def initialize(client, data)
        @id = Snowflake.new(data[:id])
        @name = data[:name]
        @icon = data[:icon] && Asset.new(self, data[:icon])
        @description = data[:description]
        @summary = data[:summary]
        @bot = data[:bot] and client.users[data[:bot][:id]] || Discorb::User.new(client, data[:bot])
      end
    end
  end
end
