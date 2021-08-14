# frozen_string_literal: true


module Discorb
  class Presence < DiscordModel
    attr_reader :status, :activities, :client_status

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

    class Activity < DiscordModel
      attr_reader :name, :type, :url, :created_at, :timestamps, :application_id, :details, :state, :emoji, :party, :assets, :instance, :buttons, :flags

      @activity_types = {
        0 => :game,
        1 => :streaming,
        2 => :listening,
        3 => :watching,
        4 => :custom,
        5 => :competing
      }
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
        @buttons = data[:buttons] && Button.new(data[:buttons])
        @flags = data[:flags] && Flag.new(data[:flags])
      end

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

      class Timestamps < DiscordModel
        attr_reader :start, :end

        def initialize(data)
          @start = data[:start] && Time.at(data[:start])
          @end = data[:end] && Time.at(data[:end])
        end
      end

      class Party < DiscordModel
        attr_reader :id

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

      class Asset < DiscordModel
        attr_reader :large_image, :large_text, :small_image, :small_text

        def initialize(data)
          @large_image = data[:large_image]
          @large_text = data[:large_text]
          @small_image = data[:small_image]
          @small_text = data[:small_text]
        end

        alias large_id large_image
        alias small_id small_text
      end

      class Flag < Discorb::Flag
        @bits = {
          instance: 0,
          join: 1,
          spectate: 2,
          join_request: 3,
          sync: 4,
          play: 5
        }
      end

      class Secrets < DiscordModel
        attr_reader :join, :spectate, :match

        def initialize(data)
          @join = data[:join]
          @spectate = data[:spectate]
          @match = data[:match]
        end
      end

      class Button < DiscordModel
        attr_reader :label, :url

        def initialize(data)
          @label = data[0]
          @url = data[1]
        end
        alias text label
      end

      class << self
        attr_reader :activity_types
      end
    end

    class ClientStatus < DiscordModel
      attr_reader :desktop, :mobile, :web

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
