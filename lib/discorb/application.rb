# frozen_string_literal: true

require_relative 'common'

module Discorb
  class Application < DiscordModel
    attr_reader :id, :name, :icon, :description, :summary, :verify_key, :owner, :team

    def initialize(client, data)
      @client = client
      @data = data
      @id = Snowflake.new(data[:id])
      @name = data[:name]
      @icon = Asset.new(self, data[:icon])
      @description = data[:description]
      @summary = data[:summary]
      @bot_public = data[:bot_public]
      @bot_require_code_grant = data[:bot_require_code_grant]
      @verify_key = data[:verify_key]
      @owner = @client.users[data[:owner][:id]] || User.new(@client, data[:owner])
      @team = data[:team] && Team.new(@client, data[:team])
    end

    def inspect
      "#<#{self.class} id=#{@id}>"
    end

    def bot_public?
      @bot_public
    end

    alias public? bot_public?

    def bot_require_code_grant?
      @bot_require_code_grant
    end

    alias require_code_grant? bot_require_code_grant?

    class Team < DiscordModel
      def initialize(client, data)
        @client = client
        @id = Snowflake.new(data[:id])
        @icon = Asset.new(self, data)
        @name = data[:name]
        @owner_user_id = data[:owner_user_id]
        @members = data[:members] || data[:member].map { |m| Team::Member.new(@client, m) }
      end

      def inspect
        "#<#{self.class} id=#{@id}>"
      end

      class Member < DiscordModel
        attr_reader :user, :team_id, :membership_state, :permissions
        alias state membership_state

        @membership_state = {
          1 => :invited,
          2 => :accepted
        }.freeze

        def initialize(client, data)
          @client = client
          @data = data
          @user = client.users[data[:user][:id]] || User.new(client, data[:user])
          @team_id = Snowflake.new(data[:team_id])
          @membership_state = self.class.membership_state[data[:membership_state]]
          @permissions = data[:permissions].map(&:to_sym)
        end

        def pending?
          @membership_state == :invited
        end

        def accepted?
          @membership_state == :accepted
        end

        def inspect
          "#<#{self.class} id=#{@id}>"
        end

        class << self
          attr_reader :membership_state
        end
      end
    end
  end
end
