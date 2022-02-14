# frozen_string_literal: true

module Discorb
  #
  # Represents a presence of user.
  #
  class Presence < DiscordModel
    # @return [:online, :idle, :dnd, :offline] The status of the user.
    attr_reader :status
    # @return [Array<Discorb::Presence::Activity>] The activities of the user.
    attr_reader :activities
    # @return [Discorb::Presence::ClientStatus] The client status of the user.
    attr_reader :client_status

    # @!attribute [r] user
    #   @return [Discorb::User] The user of the presence.
    # @!attribute [r] guild
    #   @return [Discorb::Guild] The guild of the presence.
    # @!attribute [r] activity
    #   @return [Discorb::Presence::Activity] The activity of the presence.

    # @private
    def initialize(client, data)
      @client = client
      @data = data
      _set_data(data)
    end

    def user
      @client.users[@user_id]
    end

    def guild
      @client.guilds[@guild_id]
    end

    def activity
      @activities[0]
    end

    def inspect
      "#<#{self.class} @status=#{@status.inspect} @activity=#{activity.inspect}>"
    end

    #
    # Represents an activity of a user.
    #
    class Activity < DiscordModel
      # @return [String] The name of the activity.
      attr_reader :name
      # @return [:game, :streaming, :listening, :watching, :custom, :competing] The type of the activity.
      attr_reader :type
      # @return [String] The url of the activity.
      attr_reader :url
      # @return [Time] The time the activity was created.
      attr_reader :created_at
      alias started_at created_at
      # @return [Discorb::Presence::Activity::Timestamps] The timestamps of the activity.
      attr_reader :timestamps
      # @return [Discorb::Snowflake] The application id of the activity.
      attr_reader :application_id
      # @return [String] The details of the activity.
      attr_reader :details
      # @return [String] The state of party.
      attr_reader :state
      # @return [Discorb::Emoji] The emoji of the activity.
      attr_reader :emoji
      # @return [Discorb::Presence::Activity::Party] The party of the activity.
      # @return [nil] If the activity is not a party activity.
      attr_reader :party
      # @return [Discorb::Presence::Activity::Asset] The assets of the activity.
      # @return [nil] If the activity has no assets.
      attr_reader :assets
      # @return [Discorb::StageInstance] The instance of the activity.
      # @return [nil] If the activity is not a stage activity.
      attr_reader :instance
      # @return [Array<Discorb::Presence::Activity::Button>] The buttons of the activity.
      # @return [nil] If the activity has no buttons.
      attr_reader :buttons
      # @return [Discorb::Presence::Activity::Flag] The flags of the activity.
      attr_reader :flags

      @activity_types = {
        0 => :game,
        1 => :streaming,
        2 => :listening,
        3 => :watching,
        4 => :custom,
        5 => :competing,
      }

      # @private
      def initialize(data)
        @name = data[:name]
        @type = self.class.activity_types[data[:type]]
        @url = data[:url]
        @created_at = Time.at(data[:created_at])
        @timestamps = data[:timestamps] && Timestamps.new(data[:timestamps])
        @application_id = data[:application_id] && Snowflake.new(data[:application_id])
        @details = data[:details]
        @state = data[:state]
        @emoji = if data[:emoji]
            data[:emoji][:id].nil? ? UnicodeEmoji.new(data[:emoji][:name]) : PartialEmoji.new(data[:emoji])
          end
        @party = data[:party] && Party.new(data[:party])
        @assets = data[:assets] && Asset.new(data[:assets])
        @instance = data[:instance]
        @buttons = data[:buttons]&.map { |b| Button.new(b) }
        @flags = data[:flags] && Flag.new(data[:flags])
      end

      #
      # Convert the activity to a string.
      #
      # @return [String] The string representation of the activity.
      #
      def to_s
        case @type
        when :game
          "Playing #{@name}"
        when :streaming
          "Streaming #{@details}"
        when :listening
          "Listening to #{@name}"
        when :watching
          "Watching #{@name}"
        when :custom
          "#{@emoji} #{@state}"
        when :competing
          "Competing in #{@name}"
        end
      end

      #
      # Represents the timestamps of an activity.
      #
      class Timestamps < DiscordModel
        # @return [Time] The start time of the activity.
        attr_reader :start
        # @return [Time] The end time of the activity.
        attr_reader :end

        # @private
        def initialize(data)
          @start = data[:start] && Time.at(data[:start])
          @end = data[:end] && Time.at(data[:end])
        end
      end

      #
      # Represents the party of an activity.
      #
      class Party < DiscordModel
        # @return [String] The id of the party.
        attr_reader :id

        # @!attribute [r] current_size
        #   @return [Integer] The current size of the party.
        # @!attribute [r] max_size
        #   @return [Integer] The max size of the party.

        # @private
        def initialize(data)
          @id = data[:id]
          @size = data[:size]
        end

        def current_size
          @size[0]
        end

        def max_size
          @size[1]
        end
      end

      #
      # Represents the assets of an activity.
      #
      class Asset < DiscordModel
        # @return [String] The large image ID or URL of the asset.
        attr_reader :large_image
        alias large_id large_image
        # @return [String] The large text of the activity.
        attr_reader :large_text
        # @return [String] The small image ID or URL of the activity.
        attr_reader :small_image
        alias small_id small_image
        # @return [String] The small text of the activity.
        attr_reader :small_text

        def initialize(data)
          @large_image = data[:large_image]
          @large_text = data[:large_text]
          @small_image = data[:small_image]
          @small_text = data[:small_text]
        end
      end

      #
      # Represents the flags of an activity.
      # ## Flag fields
      # |`1 << 0`|`:instance`|
      # |`1 << 1`|`:join`|
      # |`1 << 2`|`:spectate`|
      # |`1 << 3`|`:join_request`|
      # |`1 << 4`|`:sync`|
      # |`1 << 5`|`:play`|
      #
      class Flag < Discorb::Flag
        @bits = {
          instance: 0,
          join: 1,
          spectate: 2,
          join_request: 3,
          sync: 4,
          play: 5,
        }
      end

      #
      # Represents a secrets of an activity.
      #
      class Secrets < DiscordModel
        # @return [String] The join secret of the activity.
        attr_reader :join
        # @return [String] The spectate secret of the activity.
        attr_reader :spectate
        # @return [String] The match secret of the activity.
        attr_reader :match

        # @private
        def initialize(data)
          @join = data[:join]
          @spectate = data[:spectate]
          @match = data[:match]
        end
      end

      #
      # Represents a button of an activity.
      #
      class Button < DiscordModel
        # @return [String] The text of the button.
        attr_reader :label
        # @return [String] The URL of the button.
        attr_reader :url
        alias text label

        # @private
        def initialize(data)
          @label = data[0]
          @url = data[1]
        end
      end

      class << self
        # @private
        attr_reader :activity_types
      end
    end

    #
    # Represents a user's client status.
    #
    class ClientStatus < DiscordModel
      # @return [Symbol] The desktop status of the user.
      attr_reader :desktop
      # @return [Symbol] The mobile status of the user.
      attr_reader :mobile
      # @return [Symbol] The web status of the user.
      attr_reader :web

      # @!attribute [r] desktop?
      #   @return [Boolean] Whether the user is not offline on desktop.
      # @!attribute [r] mobile?
      #   @return [Boolean] Whether the user is not offline on mobile.
      # @!attribute [r] web?
      #   @return [Boolean] Whether the user is not offline on web.

      # @private
      def initialize(data)
        @desktop = data[:desktop]&.to_sym || :offline
        @mobile = data[:mobile]&.to_sym || :offline
        @web = data[:web]&.to_sym || :offline
      end

      def desktop?
        @desktop != :offline
      end

      def mobile?
        @mobile != :offline
      end

      def web?
        @web != :offline
      end
    end

    private

    def _set_data(data)
      @user_id = data[:user][:id]
      @guild_id = data[:guild_id]
      @status = data[:status].to_sym
      @activities = data[:activities].map { |a| Activity.new(a) }
      @client_status = ClientStatus.new(data[:client_status])
    end
  end
end
