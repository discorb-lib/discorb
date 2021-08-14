# frozen_string_literal: true


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
      attr_reader :id, :icon, :name, :owner_user_id, :members

      def initialize(client, data)
        @client = client
        @id = Snowflake.new(data[:id])
        @icon = Asset.new(self, data[:icon])
        @name = data[:name]
        @owner_user_id = data[:owner_user_id]
        @members = data[:members].map { |m| Team::Member.new(@client, self, m) }
      end

      def owner
        @members.find { |m| m.user.id == @owner_user_id }
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

        def initialize(client, team, data)
          @client = client
          @data = data
          @team = team
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
          "#<#{self.class} id=#{@user.id}>"
        end

        def owner?
          @team.owner_user_id == @user.id
        end

        def ==(other)
          super || @user == other
        end

        class << self
          attr_reader :membership_state
        end
      end
    end
  end
end
