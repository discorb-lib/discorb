# frozen_string_literal: true

module Discorb
  #
  # Represents an event in guild.
  #
  class ScheduledEvent < DiscordModel
    # @private
    # @return [{Integer => Symbol}] The mapping of privacy level.
    PRIVACY_LEVEL = { 2 => :guild_only }.freeze
    # @private
    # @return [{Integer => Symbol}] The mapping of status.
    STATUS = {
      1 => :scheduled,
      2 => :active,
      3 => :completed,
      4 => :canceled
    }.freeze
    # @private
    # @return [{Integer => Symbol}] The mapping of entity_type.
    ENTITY_TYPE = { 1 => :stage_instance, 2 => :voice, 3 => :external }.freeze

    # @!visibility private
    def initialize(client, data)
      @client = client
      @data = data
      _set_data(data)
    end

    #
    # Represents the metadata of the event.
    #
    class Metadata
      # @return [String, nil] The location of the event. Only present if the event is a external event.
      attr_reader :location

      # @!visibility private
      def initialize(data)
        @location = data[:location]
      end

      def inspect
        "#<#{self.class.name} #{@name}>"
      end
    end

    # @return [Discorb::Snowflake] The ID of the event.
    attr_reader :id
    # @return [String] The name of the event.
    attr_reader :name
    # @return [String] The description of the event.
    attr_reader :description

    # @return [Time] The time the event starts.
    attr_reader :scheduled_start_time
    alias start_time scheduled_start_time
    alias start_at scheduled_start_time
    # @return [Time] The time the event ends.
    attr_reader :scheduled_end_time
    alias end_time scheduled_end_time
    alias end_at scheduled_end_time
    # @return [:guild_only] The privacy level of the event.
    attr_reader :privacy_level
    # @return [:scheduled, :active, :completed, :canceled] The status of the event.
    attr_reader :status
    # @return [:stage_instance, :voice, :external] The type of the event.
    attr_reader :entity_type
    # @return [Discorb::Snowflake] The ID of the entity the event is for.
    attr_reader :entity_id
    # @return [Discorb::ScheduledEvent::Metadata] The metadata of the event.
    attr_reader :metadata
    # @return [Integer] The user count of the event.
    attr_reader :user_count

    # @!attribute [r] guild
    #   @return [Discorb::Guild, nil] The guild of the event.
    # @!attribute [r] channel
    #   @return [Discorb::Channel, nil] The channel of the event.
    #     Only present if the event will do in stage instance or voice channel.
    # @!attribute [r] creator
    #   @return [Discorb::User] The user who created the event.#
    # @!attribute [r] time
    #   @return [Range<Time>] The time range of the event.

    def guild
      @client.guilds[@guild_id]
    end

    def channel
      @client.channels[@channel_id]
    end

    def creator
      @creator || @client.users[@creator_id]
    end

    def time
      @scheduled_start_time..@scheduled_end_time
    end

    #
    # Create a scheduled event for the guild.
    # @async
    #
    # @param [:stage_instance, :voice, :external] type The type of event to create.
    # @param [String] name The name of the event.
    # @param [String] description The description of the event.
    # @param [Time] start_time The start time of the event.
    # @param [Time, nil] end_time The end time of the event. Defaults to `nil`.
    # @param [Discorb::Channel, Discorb::Snowflake, nil] channel The channel to run the event in.
    # @param [String, nil] location The location of the event. Defaults to `nil`.
    # @param [:guild_only] privacy_level The privacy level of the event. This must be `:guild_only`.
    # @param [:active, :completed, :canceled] status The status of the event.
    #
    # @return [Async::Task<Discorb::ScheduledEvent>] The event that was created.
    #
    # @see Event#start
    # @see Event#cancel
    # @see Event#complete
    #
    def edit(
      type: Discorb::Unset,
      name: Discorb::Unset,
      description: Discorb::Unset,
      start_time: Discorb::Unset,
      end_time: Discorb::Unset,
      privacy_level: Discorb::Unset,
      location: Discorb::Unset,
      channel: Discorb::Unset,
      status: Discorb::Unset
    )
      Async do
        payload =
          case type == Discorb::Unset ? @entity_type : type
          when :stage_instance
            unless channel
              raise ArgumentError,
                    "channel must be provided for stage_instance events"
            end

            {
              name:,
              description:,
              scheduled_start_time: start_time.iso8601,
              scheduled_end_time: end_time&.iso8601,
              privacy_level:
                Discorb::ScheduledEvent::PRIVACY_LEVEL.key(privacy_level) ||
                  Discorb::Unset,
              channel_id: channel&.id,
              entity_type:
                Discorb::ScheduledEvent::ENTITY_TYPE.key(:stage_instance),
              status:
                Discorb::ScheduledEvent::STATUS.key(status) || Discorb::Unset
            }.reject { |_, v| v == Discorb::Unset }
          when :voice
            unless channel
              raise ArgumentError, "channel must be provided for voice events"
            end

            {
              name:,
              description:,
              scheduled_start_time: start_time.iso8601,
              scheduled_end_time: end_time&.iso8601,
              privacy_level:
                Discorb::ScheduledEvent::PRIVACY_LEVEL.key(privacy_level) ||
                  Discorb::Unset,
              channel_id: channel&.id,
              entity_type: Discorb::ScheduledEvent::ENTITY_TYPE.key(:voice),
              status:
                Discorb::ScheduledEvent::STATUS.key(status) || Discorb::Unset
            }.reject { |_, v| v == Discorb::Unset }
          when :external
            unless location
              raise ArgumentError,
                    "location must be provided for external events"
            end
            unless end_time
              raise ArgumentError,
                    "end_time must be provided for external events"
            end

            {
              name:,
              description:,
              channel_id: nil,
              scheduled_start_time: start_time.iso8601,
              scheduled_end_time: end_time.iso8601,
              privacy_level:
                Discorb::ScheduledEvent::PRIVACY_LEVEL.key(privacy_level) ||
                  Discorb::Unset,
              entity_type: Discorb::ScheduledEvent::ENTITY_TYPE.key(:external),
              entity_metadata: {
                location:
              },
              status:
                Discorb::ScheduledEvent::STATUS.key(status) || Discorb::Unset
            }.reject { |_, v| v == Discorb::Unset }
          else
            raise ArgumentError, "Invalid scheduled event type: #{type}"
          end
        @client
          .http
          .request(
            Route.new(
              "/guilds/#{@guild_id}/scheduled-events/#{@id}",
              "//guilds/:guild_id/scheduled-events/:scheduled_event_id",
              :patch
            ),
            payload
          )
          .wait
      end
    end

    alias modify edit

    #
    # Starts the event. Shortcut for `edit(status: :active)`.
    #
    def start
      edit(status: :active)
    end

    #
    # Completes the event. Shortcut for `edit(status: :completed)`.
    #
    def complete
      edit(status: :completed)
    end

    alias finish complete

    #
    # Cancels the event. Shortcut for `edit(status: :canceled)`.
    #
    def cancel
      edit(status: :canceled)
    end

    #
    # Deletes the event.
    # @async
    #
    # @return [Async::Task<void>] The task.
    #
    def delete
      Async do
        @client
          .http
          .request(
            Route.new(
              "/guilds/#{@guild_id}/scheduled-events/#{@id}",
              "//guilds/:guild_id/scheduled-events/:scheduled_event_id",
              :delete
            )
          )
          .wait
      end
    end

    alias destroy delete

    #
    # Fetches the event users.
    # @async
    #
    # @note You can fetch all of members by not specifying a parameter.
    #
    # @param [Integer] limit The maximum number of users to fetch. Defaults to `100`.
    # @param [#to_s] after The ID of the user to start fetching from. Defaults to `nil`.
    # @param [#to_s] before The ID of the user to stop fetching at. Defaults to `nil`.
    # @param [Boolean] with_member Whether to include the member object of the event. Defaults to `false`.
    #   This should be used for manual fetching of members.
    #
    # @return [Async::Task<Array<Discorb::Member>>] The event users.
    #
    def fetch_users(limit = nil, before: nil, after: nil, with_member: true)
      Async do
        if limit.nil?
          after = 0
          res = []
          loop do
            _resp, users =
              @client
                .http
                .request(
                  Route.new(
                    "/guilds/#{@guild_id}/scheduled-events/#{@id}/users?limit=100&after=#{after}&with_member=true",
                    "//guilds/:guild_id/scheduled-events/:scheduled_event_id/users",
                    :get
                  )
                )
                .wait
            break if users.empty?

            res +=
              users.map do |u|
                Member.new(@client, @guild_id, u[:user], u[:member])
              end
            after = users.last[:user][:id]
          end
          res
        else
          params =
            {
              limit:,
              before: Discorb::Utils.try(before, :id),
              after: Discorb::Utils.try(after, :id),
              with_member:
            }.filter { |_k, v| !v.nil? }.to_h
          _resp, messages =
            @client
              .http
              .request(
                Route.new(
                  "/channels/#{channel_id.wait}/messages?#{URI.encode_www_form(params)}",
                  "//channels/:channel_id/messages",
                  :get
                )
              )
              .wait
          messages.map do |m|
            Message.new(@client, m.merge({ guild_id: @guild_id.to_s }))
          end
        end
      end
    end

    alias fetch_members fetch_users

    private

    def _set_data(data)
      @id = Snowflake.new(data[:id])
      @guild_id = Snowflake.new(data[:guild_id])
      @channel_id = data[:channel_id] && Snowflake.new(data[:channel_id])
      @creator_id = data[:creator_id] && Snowflake.new(data[:creator_id])
      @name = data[:name]
      @description = data[:description]
      @scheduled_start_time = Time.iso8601(data[:scheduled_start_time])
      @scheduled_end_time =
        data[:scheduled_end_time] && Time.iso8601(data[:scheduled_end_time])
      @privacy_level = :guild_only # data[:privacy_level]
      @status = STATUS[data[:status]]
      @entity_type = ENTITY_TYPE[data[:entity_type]]
      @entity_id = data[:entity_id] && Snowflake.new(data[:entity_id])
      @entity_metadata =
        data[:entity_metadata] && Metadata.new(data[:entity_metadata])
      @creator =
        @client.users[@creator_id] ||
          (data[:creator] && User.new(@client, data[:creator]))
      @user_count = data[:user_count]
    end

    class << self
      attr_reader :status, :entity_type, :privacy_level
    end
  end
end
