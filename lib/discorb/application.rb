# frozen_string_literal: true

module Discorb
  #
  # Represents a Discord application.
  #
  class Application < DiscordModel
    # @return [Discorb::Snowflake] The application's ID.
    attr_reader :id
    # @return [String] The application's name.
    attr_reader :name
    # @return [Discorb::Asset] The application's icon.
    attr_reader :icon
    # @return [String] The application's description.
    attr_reader :description
    # @return [String] The application's summary.
    attr_reader :summary
    # @return [String] The application's public key.
    attr_reader :verify_key
    # @return [Discorb::User] The application's owner.
    attr_reader :owner
    # @return [Discorb::Application::Team] The application's team.
    attr_reader :team
    # @return [Boolean] Whether the application's bot is public.
    attr_reader :bot_public
    alias bot_public? bot_public
    # @return [Boolean] Whether the application's bot requires a code grant.
    attr_reader :bot_require_code_grant
    alias bot_require_code_grant? bot_require_code_grant

    # @!visibility private
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

    alias public? bot_public?

    alias require_code_grant? bot_require_code_grant?

    #
    # Represents a team for an application.
    #
    class Team < DiscordModel
      # @return [Discorb::Snowflake] The team's ID.
      attr_reader :id
      # @return [Discorb::Asset] The team's icon.
      attr_reader :icon
      # @return [String] The team's name.
      attr_reader :name
      # @return [Discorb::Snowflake] The team's owner's ID.
      attr_reader :owner_user_id
      # @return [Discorb::Application::Team::Member] The team's member.
      attr_reader :members

      # @!visibility private
      def initialize(client, data)
        @client = client
        @id = Snowflake.new(data[:id])
        @icon = Asset.new(self, data[:icon])
        @name = data[:name]
        @owner_user_id = data[:owner_user_id]
        @members = data[:members].map { |m| Team::Member.new(@client, self, m) }
      end

      #
      # The team's owner.
      #
      # @return [Discorb::Application::Team::Member] The team's owner.
      #
      def owner
        @members.find { |m| m.user.id == @owner_user_id }
      end

      def inspect
        "#<#{self.class} id=#{@id}>"
      end

      #
      # Represents a member of team.
      #
      class Member < DiscordModel
        # @return [Discorb::User] The user.
        attr_reader :user
        # @return [Snowflake] The ID of member's team.
        attr_reader :team_id
        # @return [:invited, :accepted] The member's membership state.
        attr_reader :membership_state
        alias state membership_state
        # @return [Array<Permissions>] The permissions of the member.
        # @note This always return `:*`.
        attr_reader :permissions

        # @!attribute [r] pending?
        #   @return [Boolean] Whether the member is not joined to the team.
        # @!attribute [r] accepted?
        #   @return [Boolean] Whether the member accepted joining the team.
        # @!attribute [r] owner?
        #   @return [Boolean] Whether the member is the team's owner.

        @membership_state = {
          1 => :invited,
          2 => :accepted,
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
          # @!visibility private
          attr_reader :membership_state
        end
      end
    end
  end
end
