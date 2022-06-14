# frozen_string_literal: true

require "async/http"
require "async/websocket"
require "async/barrier"
require "json"
require "zlib"

module Discorb
  #
  # A module for Discord Gateway.
  # This module is internal use only.
  #
  module Gateway
    #
    # Represents an event.
    # @abstract
    #
    class GatewayEvent
      #
      # Initializes a new instance of the GatewayEvent class.
      # @private
      #
      # @param [Hash] data The data of the event.
      #
      def initialize(data)
        @data = data
      end

      def inspect
        "#<#{self.class}>"
      end
    end

    #
    # Represents a reaction event.
    #
    class ReactionEvent < GatewayEvent
      # @return [Hash] The raw data of the event.
      attr_reader :data
      # @return [Discorb::Snowflake] The ID of the user who reacted.
      attr_reader :user_id
      alias member_id user_id
      # @return [Discorb::Snowflake] The ID of the channel the message was sent in.
      attr_reader :channel_id
      # @return [Discorb::Snowflake] The ID of the message.
      attr_reader :message_id
      # @return [Discorb::Snowflake] The ID of the guild the message was sent in.
      attr_reader :guild_id
      # @macro client_cache
      # @return [Discorb::User, Discorb::Member] The user who reacted.
      attr_reader :user
      alias member user
      # @macro client_cache
      # @return [Discorb::Channel] The channel the message was sent in.
      attr_reader :channel
      # @macro client_cache
      # @return [Discorb::Guild] The guild the message was sent in.
      attr_reader :guild
      # @macro client_cache
      # @return [Discorb::Message] The message the reaction was sent in.
      attr_reader :message
      # @return [Discorb::UnicodeEmoji, Discorb::PartialEmoji] The emoji that was reacted with.
      attr_reader :emoji

      #
      # Initializes a new instance of the ReactionEvent class.
      # @private
      #
      # @param [Discorb::Client] client The client that instantiated the object.
      # @param [Hash] data The data of the event.
      #
      def initialize(client, data)
        @client = client
        @data = data
        if data.key?(:user_id)
          @user_id = Snowflake.new(data[:user_id])
        else
          @member_data = data[:member]
        end
        @channel_id = Snowflake.new(data[:channel_id])
        @message_id = Snowflake.new(data[:message_id])
        @guild_id = Snowflake.new(data[:guild_id])
        @guild = client.guilds[data[:guild_id]]
        @channel = client.channels[data[:channel_id]] unless @guild.nil?

        @user = client.users[data[:user_id]]

        unless @guild.nil?
          @user = if data.key?(:member)
              @guild.members[data[:member][:user][:id]] || Member.new(@client, @guild_id, data[:member][:user],
                                                                      data[:member])
            else
              @guild.members[data[:user_id]]
            end || @user
        end

        @message = client.messages[data[:message_id]]
        @emoji = data[:emoji][:id].nil? ? UnicodeEmoji.new(data[:emoji][:name]) : PartialEmoji.new(data[:emoji])
      end

      # Fetch the message.
      # If message is cached, it will be returned.
      # @async
      #
      # @param [Boolean] force Whether to force fetching the message.
      #
      # @return [Async::Task<Discorb::Message>] The message.
      def fetch_message(force: false)
        Async do
          next @message if !force && @message

          @message = @channel.fetch_message(@message_id).wait
        end
      end
    end

    #
    # Represents a `INTEGRATION_DELETE` event.
    #
    class IntegrationDeleteEvent < GatewayEvent
      # @return [Discorb::Snowflake] The ID of the integration.
      attr_reader :id

      # @!attribute [r] guild
      #   @macro client_cache
      #   @return [Discorb::Guild] The guild of the integration.
      # @!attribute [r] user
      #   @macro client_cache
      #   @return [Discorb::User] The user associated with the integration.

      #
      # Initialize a new instance of the IntegrationDeleteEvent class.
      # @private
      #
      #
      # @param [Hash] data The data of the event.
      #
      #
      def initialize(_client, data)
        @id = Snowflake.new(data[:id])
        @guild_id = data[:guild_id]
        @user_id = data[:application_id]
      end

      def guild
        @client.guilds[@guild_id]
      end

      def user
        @client.users[@user_id]
      end
    end

    #
    # Represents a `MESSAGE_REACTION_REMOVE_ALL` event.
    #
    class ReactionRemoveAllEvent < GatewayEvent
      # @return [Discorb::Snowflake] The ID of the channel the message was sent in.
      attr_reader :channel_id
      # @return [Discorb::Snowflake] The ID of the message.
      attr_reader :message_id
      # @return [Discorb::Snowflake] The ID of the guild the message was sent in.
      attr_reader :guild_id
      # @macro client_cache
      # @return [Discorb::Channel] The channel the message was sent in.
      attr_reader :channel
      # @macro client_cache
      # @return [Discorb::Guild] The guild the message was sent in.
      attr_reader :guild
      # @macro client_cache
      # @return [Discorb::Message] The message the reaction was sent in.
      attr_reader :message

      #
      # Initialize a new instance of the ReactionRemoveAllEvent class.
      # @private
      #
      # @param [Discorb::Client] client The client that instantiated the object.
      # @param [Hash] data The data of the event.
      #
      def initialize(client, data)
        @client = client
        @data = data
        @guild_id = Snowflake.new(data[:guild_id])
        @channel_id = Snowflake.new(data[:channel_id])
        @message_id = Snowflake.new(data[:message_id])
        @guild = client.guilds[data[:guild_id]]
        @channel = client.channels[data[:channel_id]]
        @message = client.messages[data[:message_id]]
      end

      # Fetch the message.
      # If message is cached, it will be returned.
      # @async
      #
      # @param [Boolean] force Whether to force fetching the message.
      #
      # @return [Async::Task<Discorb::Message>] The message.
      def fetch_message(force: false)
        Async do
          next @message if !force && @message

          @message = @channel.fetch_message(@message_id).wait
        end
      end
    end

    #
    # Represents a `MESSAGE_REACTION_REMOVE_EMOJI` event.
    #
    class ReactionRemoveEmojiEvent < GatewayEvent
      # @return [Discorb::Snowflake] The ID of the channel the message was sent in.
      attr_reader :channel_id
      # @return [Discorb::Snowflake] The ID of the message.
      attr_reader :message_id
      # @return [Discorb::Snowflake] The ID of the guild the message was sent in.
      attr_reader :guild_id
      # @macro client_cache
      # @return [Discorb::Channel] The channel the message was sent in.
      attr_reader :channel
      # @macro client_cache
      # @return [Discorb::Guild] The guild the message was sent in.
      attr_reader :guild
      # @macro client_cache
      # @return [Discorb::Message] The message the reaction was sent in.
      attr_reader :message
      # @return [Discorb::UnicodeEmoji, Discorb::PartialEmoji] The emoji that was reacted with.
      attr_reader :emoji

      #
      # Initialize a new instance of the ReactionRemoveEmojiEvent class.
      # @private
      #
      # @param [Discorb::Client] client The client that instantiated the object.
      # @param [Hash] data The data of the event.
      #
      def initialize(client, data)
        @client = client
        @data = data
        @guild_id = Snowflake.new(data[:guild_id])
        @channel_id = Snowflake.new(data[:channel_id])
        @message_id = Snowflake.new(data[:message_id])
        @guild = client.guilds[data[:guild_id]]
        @channel = client.channels[data[:channel_id]]
        @message = client.messages[data[:message_id]]
        @emoji = data[:emoji][:id].nil? ? DiscordEmoji.new(data[:emoji][:name]) : PartialEmoji.new(data[:emoji])
      end

      # Fetch the message.
      # If message is cached, it will be returned.
      # @async
      #
      # @param [Boolean] force Whether to force fetching the message.
      #
      # @return [Async::Task<Discorb::Message>] The message.
      def fetch_message(force: false)
        Async do
          next @message if !force && @message

          @message = @channel.fetch_message(@message_id).wait
        end
      end
    end

    #
    # Represents a `GUILD_SCHEDULED_EVENT_USER_ADD` and `GUILD_SCHEDULED_EVENT_USER_REMOVE` event.
    #
    class ScheduledEventUserEvent < GatewayEvent
      # @return [Discorb::User] The user that triggered the event.
      attr_reader :user
      # @return [Discorb::Guild] The guild the event was triggered in.
      attr_reader :guild
      # @return [Discorb::ScheduledEvent] The scheduled event.
      attr_reader :scheduled_event

      #
      # Initialize a new instance of the ScheduledEventUserEvent class.
      # @private
      #
      # @param [Discorb::Client] client The client that instantiated the object.
      # @param [Hash] data The data of the event.
      #
      def initialize(client, data)
        @client = client
        @scheduled_event_id = Snowflake.new(data[:scheduled_event_id])
        @user_id = Snowflake.new(data[:user_id])
        @guild_id = Snowflake.new(data[:guild_id])
        @guild = client.guilds[data[:guild_id]]
        @scheduled_event = @guild.scheduled_events[@scheduled_event_id]
        @user = client.users[data[:user_id]]
      end
    end

    #
    # Represents a `MESSAGE_UPDATE` event.
    #
    class MessageUpdateEvent < GatewayEvent
      # @return [Discorb::Message] The message before update.
      attr_reader :before
      # @return [Discorb::Message] The message after update.
      attr_reader :after
      # @return [Discorb::Snowflake] The ID of the message.
      attr_reader :id
      # @return [Discorb::Snowflake] The ID of the channel the message was sent in.
      attr_reader :channel_id
      # @return [Discorb::Snowflake] The ID of the guild the message was sent in.
      attr_reader :guild_id
      # @return [String] The new content of the message.
      attr_reader :content
      # @return [Time] The time the message was edited.
      attr_reader :timestamp
      # @return [Boolean] Whether the message pings @everyone.
      attr_reader :mention_everyone
      # @macro client_cache
      # @return [Array<Discorb::Role>] The roles mentioned in the message.
      attr_reader :mention_roles
      # @return [Array<Discorb::Attachment>] The attachments in the message.
      attr_reader :attachments
      # @return [Array<Discorb::Embed>] The embeds in the message.
      attr_reader :embeds

      # @!attribute [r] channel
      #   @macro client_cache
      #   @return [Discorb::Channel] The channel the message was sent in.
      # @!attribute [r] guild
      #   @macro client_cache
      #   @return [Discorb::Guild] The guild the message was sent in.

      def initialize(client, data, before, after)
        @client = client
        @data = data
        @before = before
        @after = after
        @id = Snowflake.new(data[:id])
        @channel_id = Snowflake.new(data[:channel_id])
        @guild_id = Snowflake.new(data[:guild_id]) if data.key?(:guild_id)
        @content = data[:content]
        @timestamp = Time.iso8601(data[:edited_timestamp])
        @mention_everyone = data[:mention_everyone]
        @mention_roles = data[:mention_roles].map { |r| guild.roles[r] } if data.key?(:mention_roles)
        @attachments = data[:attachments].map { |a| Attachment.from_hash(a) } if data.key?(:attachments)
        @embeds = data[:embeds] ? data[:embeds].map { |e| Embed.from_hash(e) } : [] if data.key?(:embeds)
      end

      def channel
        @client.channels[@channel_id]
      end

      def guild
        @client.guilds[@guild_id]
      end

      # Fetch the message.
      # @async
      #
      # @return [Async::Task<Discorb::Message>] The message.
      def fetch_message
        Async do
          channel.fetch_message(@id).wait
        end
      end
    end

    #
    # Represents a message but it has only ID.
    #
    class UnknownDeleteBulkMessage < GatewayEvent
      # @return [Discorb::Snowflake] The ID of the message.
      attr_reader :id

      # @!attribute [r] channel
      #   @macro client_cache
      #   @return [Discorb::Channel] The channel the message was sent in.
      # @!attribute [r] guild
      #   @macro client_cache
      #   @return [Discorb::Guild] The guild the message was sent in.

      #
      # Initialize a new instance of the UnknownDeleteBulkMessage class.
      # @private
      #
      # @param [Discorb::Client] client The client that instantiated the object.
      # @param [Hash] data The data of the event.
      #
      def initialize(client, id, data)
        @client = client
        @id = Snowflake.new(id)
        @data = data
        @channel_id = Snowflake.new(data[:channel_id])
        @guild_id = Snowflake.new(data[:guild_id]) if data.key?(:guild_id)
      end

      def channel
        @client.channels[@channel_id]
      end

      def guild
        @client.guilds[@guild_id]
      end
    end

    #
    # Represents a `INVITE_DELETE` event.
    #
    class InviteDeleteEvent < GatewayEvent
      # @return [String] The invite code.
      attr_reader :code

      # @!attribute [r] channel
      #   @macro client_cache
      #   @return [Discorb::Channel] The channel the message was sent in.
      # @!attribute [r] guild
      #   @macro client_cache
      #   @return [Discorb::Guild] The guild the message was sent in.

      #
      # Initialize a new instance of the InviteDeleteEvent class.
      # @private
      #
      # @param [Discorb::Client] client The client that instantiated the object.
      # @param [Hash] data The data of the event.
      #
      def initialize(client, data)
        @client = client
        @data = data
        @channel_id = Snowflake.new(data[:channel])
        @guild_id = Snowflake.new(data[:guild_id])
        @code = data[:code]
      end

      def channel
        @client.channels[@channel_id]
      end

      def guild
        @client.guilds[@guild_id]
      end
    end

    #
    # Represents a `TYPING_START` event.
    #
    class TypingStartEvent < GatewayEvent
      # @return [Discorb::Snowflake] The ID of the channel the user is typing in.
      attr_reader :user_id

      # @!attribute [r] channel
      #   @macro client_cache
      #   @return [Discorb::Channel] The channel the user is typing in.
      # @!attribute [r] guild
      #   @macro client_cache
      #   @return [Discorb::Guild] The guild the user is typing in.
      # @!attribute [r] user
      #   @macro client_cache
      #   @return [Discorb::User, Discorb::Member] The user that is typing.

      #
      # Initialize a new instance of the TypingStartEvent class.
      # @private
      #
      # @param [Discorb::Client] client The client that instantiated the object.
      # @param [Hash] data The data of the event.
      #
      def initialize(client, data)
        @client = client
        @data = data
        @channel_id = Snowflake.new(data[:channel_id])
        @guild_id = Snowflake.new(data[:guild_id]) if data.key?(:guild_id)
        @user_id = Snowflake.new(data[:user_id])
        @timestamp = Time.at(data[:timestamp])
        if guild
          @member = guild.members[@user_id] || Member.new(
            @client,
            @guild_id,
            @client.users[@user_id].instance_variable_get(:@data),
            data[:member]
          )
        end
      end

      def user
        @member || guild&.members&.[](@user_id) || @client.users[@user_id]
      end
      alias member user

      def channel
        @client.channels[@channel_id]
      end

      def guild
        @client.guilds[@guild_id]
      end
    end

    #
    # Represents a message pin event.
    #
    class MessagePinEvent < GatewayEvent
      # @return [Discorb::Message] The message that was pinned.
      attr_reader :message
      # @return [:pinned, :unpinned] The type of event.
      attr_reader :type

      # @!attribute [r] pinned?
      #   @return [Boolean] Whether the message was pinned.
      # @!attribute [r] unpinned?
      #   @return [Boolean] Whether the message was unpinned.

      def initialize(client, data, message)
        @client = client
        @data = data
        @message = message
        @type = if message.nil?
            :unknown
          elsif @message.pinned?
            :pinned
          else
            :unpinned
          end
      end

      def pinned?
        @type == :pinned
      end

      def unpinned?
        @type == :unpinned
      end
    end

    #
    # Represents a `WEBHOOKS_UPDATE` event.
    #
    class WebhooksUpdateEvent < GatewayEvent
      # @!attribute [r] channel
      #   @macro client_cache
      #   @return [Discorb::Channel] The channel where the webhook was updated.
      # @!attribute [r] guild
      #   @macro client_cache
      #   @return [Discorb::Guild] The guild where the webhook was updated.

      #
      # Initialize a new instance of the WebhooksUpdateEvent class.
      # @private
      #
      # @param [Discorb::Client] client The client that instantiated the object.
      # @param [Hash] data The data of the event.
      #
      def initialize(client, data)
        @client = client
        @data = data
        @guild_id = Snowflake.new(data[:guild_id])
        @channel_id = Snowflake.new(data[:channel_id])
      end

      def guild
        @client.guilds[@guild_id]
      end

      def channel
        @client.channels[@channel_id]
      end
    end

    #
    # A module to handle gateway events.
    #
    module Handler
      # @type instance: Discorb::Client

      private

      def connect_gateway(reconnect)
        Async do
          @mutex["gateway_#{shard_id}"] ||= Mutex.new
          @mutex["gateway_#{shard_id}"].synchronize do
            if reconnect
              logger.info "Reconnecting to gateway..."
            else
              logger.info "Connecting to gateway..."
            end

            @http = HTTP.new(self)
            _, gateway_response = @http.request(Route.new("/gateway", "//gateway", :get)).wait
            gateway_url = gateway_response[:url]
            gateway_version = if @intents.to_h[:message_content].nil?
                unless @message_content_intent_warned
                  warn "message_content intent not set, using gateway version 9. " \
                       "You should specify `message_content` intent for preventing unexpected changes in the future."
                  @message_content_intent_warned = true
                end
                9
              else
                10
              end
            endpoint = Async::HTTP::Endpoint.parse(
              "#{gateway_url}?v=#{gateway_version}&encoding=json&compress=zlib-stream&_=#{Time.now.to_i}",
              alpn_protocols: Async::HTTP::Protocol::HTTP11.names,
            )
            begin
              self.connection = Async::WebSocket::Client.connect(
                endpoint,
                headers: [["User-Agent", Discorb::USER_AGENT]],
                handler: RawConnection,
              )
              zlib_stream = Zlib::Inflate.new(Zlib::MAX_WBITS)
              buffer = +""
              begin
                while (message = connection.read)
                  buffer << message
                  if message.end_with?((+"\x00\x00\xff\xff").force_encoding("ASCII-8BIT"))
                    begin
                      data = zlib_stream.inflate(buffer)
                      buffer = +""
                      message = JSON.parse(data, symbolize_names: true)
                    rescue JSON::ParserError
                      buffer = +""
                      logger.error "Received invalid JSON from gateway."
                      logger.debug "#{data}"
                    else
                      handle_gateway(message, reconnect)
                    end
                  end
                end
              rescue Async::Wrapper::Cancelled,
                     OpenSSL::SSL::SSLError,
                     Async::Wrapper::WaitError,
                     EOFError,
                     Errno::EPIPE,
                     Errno::ECONNRESET,
                     IOError => e
                next if @status == :closed

                logger.error "Gateway connection closed accidentally: #{e.class}: #{e.message}"
                connection.force_close
                connect_gateway(true)
                next
              end
            rescue Protocol::WebSocket::ClosedError => e
              @tasks.map(&:stop)
              case e.code
              when 4004
                raise ClientError.new("Authentication failed"), cause: nil
              when 4009
                logger.info "Session timed out, reconnecting."
                connection.force_close
                connect_gateway(true)
                next
              when 4014
                raise ClientError.new("Disallowed intents were specified"), cause: nil
              when 4001, 4002, 4003, 4005, 4007
                raise ClientError.new(<<~ERROR), cause: e
                                                   Disconnected from gateway, probably due to library issues.
                                                   #{e.message}

                                                   Please report this to the library issue tracker.
                                                   https://github.com/discorb-lib/discorb/issues
                                                 ERROR
              when 1001
                logger.info "Gateway closed with code 1001, reconnecting."
                connection.force_close
                connect_gateway(true)
                next
              else
                logger.error "Discord WebSocket closed with code #{e.code}."
                logger.debug "#{e.message}"
                connection.force_close
                connect_gateway(false)
                next
              end
            rescue StandardError => e
              logger.error "Discord WebSocket error: #{e.full_message}"
              connection.force_close
              connect_gateway(false)
              next
            end
          end
        end
      end

      def send_gateway(opcode, **value)
        if @shards.any? && shard.nil?
          @shards.map(&:connection)
        else
          [connection]
        end.each do |con|
          con.write({ op: opcode, d: value }.to_json)
          con.flush
        end
        logger.debug "Sent message to fd #{connection.io.fileno}: #{{ op: opcode, d: value }.to_json.gsub(@token,
                                                                                                          "[Token]")}"
      end

      def handle_gateway(payload, reconnect)
        Async do |_task|
          data = payload[:d]
          @last_s = payload[:s] if payload[:s]
          logger.debug "Received message with opcode #{payload[:op]} from gateway."
          logger.debug "#{payload.to_json.gsub(@token, "[Token]")}"
          case payload[:op]
          when 10
            @heartbeat_interval = data[:heartbeat_interval]
            if reconnect
              payload = {
                token: @token,
                session_id: session_id,
                seq: @last_s,
              }
              send_gateway(6, **payload)
            else
              payload = {
                token: @token,
                intents: @intents.value,
                compress: false,
                properties: { "$os" => RUBY_PLATFORM, "$browser" => "discorb", "$device" => "discorb" },
              }
              payload[:shard] = [shard_id, @shard_count] if shard_id
              payload[:presence] = @identify_presence if @identify_presence
              send_gateway(2, **payload)
            end
          when 7
            logger.info "Received opcode 7, stopping tasks"
            @tasks.map(&:stop)
          when 9
            logger.warn "Received opcode 9, closed connection"
            @tasks.map(&:stop)
            if data
              logger.info "Connection is resumable, reconnecting"
              connection.force_close
              connect_gateway(true)
            else
              logger.info "Connection is not resumable, reconnecting with opcode 2"
              connection.force_close

              sleep(2)
              connect_gateway(false)
            end
          when 11
            logger.debug "Received opcode 11"
            @ping = Time.now.to_f - @heartbeat_before
          when 0
            handle_event(payload[:t], data)
          end
        end
      end

      def handle_heartbeat
        Async do |_task|
          interval = @heartbeat_interval
          sleep((interval / 1000.0 - 1) * rand)
          loop do
            unless connection.closed?
              @heartbeat_before = Time.now.to_f
              connection.write({ op: 1, d: @last_s }.to_json)
              connection.flush
              logger.debug "Sent opcode 1."
              logger.debug "Waiting for heartbeat."
            end
            sleep(interval / 1000.0 - 1)
          end
        end
      end

      def handle_event(event_name, data)
        return logger.debug "Client isn't ready; event #{event_name} wasn't handled" if @wait_until_ready &&
                                                                                        !@ready &&
                                                                                        !%w[
                                                                                          READY GUILD_CREATE
                                                                                        ].include?(event_name)

        dispatch(:event_receive, event_name, data)
        logger.debug "Handling event #{event_name}"
        case event_name
        when "READY"
          @api_version = data[:v]
          self.session_id = data[:session_id]
          @user = ClientUser.new(self, data[:user])
          @uncached_guilds = data[:guilds].map { |g| g[:id] }
          ready if (@uncached_guilds == []) || !@intents.guilds
          dispatch(:ready)

          @tasks << handle_heartbeat
        when "GUILD_CREATE"
          if @uncached_guilds.include?(data[:id])
            Guild.new(self, data, true)
            @uncached_guilds.delete(data[:id])
            if @uncached_guilds == []
              logger.debug "All guilds cached"
              ready
            end
          elsif @guilds.has?(data[:id])
            @guilds[data[:id]].send(:_set_data, data, true)
            dispatch(:guild_available, guild)
          else
            guild = Guild.new(self, data, true)
            dispatch(:guild_join, guild)
          end
          dispatch(:guild_create, @guilds[data[:id]])
        when "MESSAGE_CREATE"
          message = Message.new(self, data)
          dispatch(:message, message)
        when "GUILD_UPDATE"
          if @guilds.has?(data[:id])
            current = @guilds[data[:id]]
            before = Guild.new(self, current.instance_variable_get(:@data).merge(no_cache: true), false)
            current.send(:_set_data, data, false)
            dispatch(:guild_update, before, current)
          else
            logger.warn "Unknown guild id #{data[:id]}, ignoring"
          end
        when "GUILD_DELETE"
          return logger.warn "Unknown guild id #{data[:id]}, ignoring" unless (guild = @guilds.delete(data[:id]))

          dispatch(:guild_delete, guild)
          if data[:unavailable]
            dispatch(:guild_destroy, guild)
          else
            dispatch(:guild_leave, guild)
          end
        when "GUILD_ROLE_CREATE"
          return logger.warn "Unknown guild id #{data[:guild_id]}, ignoring" unless (guild = @guilds[data[:guild_id]])

          nr = Role.new(@client, guild, data[:role])
          guild.roles[data[:role][:id]] = nr
          dispatch(:role_create, nr)
        when "GUILD_ROLE_UPDATE"
          return logger.warn "Unknown guild id #{data[:guild_id]}, ignoring" unless (guild = @guilds[data[:guild_id]])
          return logger.warn "Unknown role id #{data[:role][:id]}, ignoring" unless guild.roles.has?(data[:role][:id])

          current = guild.roles[data[:role][:id]]
          before = Role.new(@client, guild, current.instance_variable_get(:@data).update({ no_cache: true }))
          current.send(:_set_data, data[:role])
          dispatch(:role_update, before, current)
        when "GUILD_ROLE_DELETE"
          return logger.warn "Unknown guild id #{data[:guild_id]}, ignoring" unless (guild = @guilds[data[:guild_id]])
          unless (role = guild.roles.delete(data[:role_id]))
            return logger.warn "Unknown role id #{data[:role_id]}, ignoring"
          end

          dispatch(:role_delete, role)
        when "CHANNEL_CREATE"
          return logger.warn "Unknown guild id #{data[:guild_id]}, ignoring" unless (guild = @guilds[data[:guild_id]])

          nc = Channel.make_channel(self, data)
          guild.channels[data[:id]] = nc

          dispatch(:channel_create, nc)
        when "CHANNEL_UPDATE"
          return logger.warn "Unknown channel id #{data[:id]}, ignoring" unless (current = @channels[data[:id]])

          before = Channel.make_channel(self, current.instance_variable_get(:@data), no_cache: true)
          current.send(:_set_data, data)
          dispatch(:channel_update, before, current)
        when "CHANNEL_DELETE"
          return logger.warn "Unknown channel id #{data[:id]}, ignoring" unless (channel = @channels.delete(data[:id]))

          @guilds[data[:guild_id]]&.channels&.delete(data[:id])
          dispatch(:channel_delete, channel)
        when "CHANNEL_PINS_UPDATE"
          nil # do in MESSAGE_UPDATE
        when "THREAD_CREATE"
          thread = Channel.make_channel(self, data)

          dispatch(:thread_create, thread)
          if data.key?(:member)
            dispatch(:thread_join, thread)
          else
            dispatch(:thread_new, thread)
          end
        when "THREAD_UPDATE"
          return logger.warn "Unknown thread id #{data[:id]}, ignoring" unless (thread = @channels[data[:id]])

          before = Channel.make_channel(self, thread.instance_variable_get(:@data), no_cache: true)
          thread.send(:_set_data, data)
          dispatch(:thread_update, before, thread)
        when "THREAD_DELETE"
          return logger.warn "Unknown thread id #{data[:id]}, ignoring" unless (thread = @channels.delete(data[:id]))

          @guilds[data[:guild_id]]&.channels&.delete(data[:id])
          dispatch(:thread_delete, thread)
        when "THREAD_LIST_SYNC"
          data[:threads].each do |raw_thread|
            thread = Channel.make_channel(self, raw_thread.merge({ member: raw_thread[:members].find do |m|
              m[:id] == raw_thread[:id]
            end }))
            @channels[thread.id] = thread
          end
        when "THREAD_MEMBER_UPDATE"
          return logger.warn "Unknown thread id #{data[:id]}, ignoring" unless (thread = @channels[data[:id]])

          if (member = thread.members[data[:id]])
            old = ThreadChannel::Member.new(self, member.instance_variable_get(:@data), data[:guild_id])
            member.send(:_set_data, data)
          else
            old = nil
            member = ThreadChannel::Member.new(self, data, data[:guild_id])
            thread.members[data[:user_id]] = member
          end
          dispatch(:thread_member_update, thread, old, member)
        when "THREAD_MEMBERS_UPDATE"
          return logger.warn "Unknown thread id #{data[:id]}, ignoring" unless (thread = @channels[data[:id]])

          thread.instance_variable_set(:@member_count, data[:member_count])
          members = []
          (data[:added_members] || []).each do |raw_member|
            member = ThreadChannel::Member.new(self, raw_member, data[:guild_id])
            thread.members[member.id] = member
            members << member
          end
          removed_members = []
          (data[:removed_member_ids] || []).each do |id|
            removed_members << thread.members.delete(id)
          end
          dispatch(:thread_members_update, thread, members, removed_members)
        when "STAGE_INSTANCE_CREATE"
          instance = StageInstance.new(self, data)
          dispatch(:stage_instance_create, instance)
        when "STAGE_INSTANCE_UPDATE"
          unless (channel = @channels[data[:channel_id]])
            return logger.warn "Unknown channel id #{data[:channel_id]} , ignoring"
          end
          unless (instance = channel.stage_instances[data[:id]])
            return logger.warn "Unknown stage instance id #{data[:id]}, ignoring"
          end

          old = StageInstance.new(self, instance.instance_variable_get(:@data), no_cache: true)
          current.send(:_set_data, data)
          dispatch(:stage_instance_update, old, current)
        when "STAGE_INSTANCE_DELETE"
          unless (channel = @channels[data[:channel_id]])
            return logger.warn "Unknown channel id #{data[:channel_id]} , ignoring"
          end
          unless (instance = channel.stage_instances.delete(data[:id]))
            return logger.warn "Unknown stage instance id #{data[:id]}, ignoring"
          end

          dispatch(:stage_instance_delete, instance)
        when "GUILD_MEMBER_ADD"
          return logger.warn "Unknown guild id #{data[:guild_id]}, ignoring" unless (guild = @guilds[data[:guild_id]])

          nm = Member.new(self, data[:guild_id], data[:user].update({ no_cache: true }), data)
          guild.members[nm.id] = nm
          dispatch(:member_add, nm)
        when "GUILD_MEMBER_UPDATE"
          return logger.warn "Unknown guild id #{data[:guild_id]}, ignoring" unless (guild = @guilds[data[:guild_id]])
          unless (nm = guild.members[data[:user][:id]])
            return logger.warn "Unknown member id #{data[:user][:id]}, ignoring"
          end

          old = Member.new(self, data[:guild_id], data[:user], data.update({ no_cache: true }))
          nm.send(:_set_data, data[:user], data)
          dispatch(:member_update, old, nm)
        when "GUILD_MEMBER_REMOVE"
          return logger.warn "Unknown guild id #{data[:guild_id]}, ignoring" unless (guild = @guilds[data[:guild_id]])
          unless (member = guild.members.delete(data[:user][:id]))
            return logger.warn "Unknown member id #{data[:user][:id]}, ignoring"
          end

          dispatch(:member_remove, member)
        when "GUILD_BAN_ADD"
          return logger.warn "Unknown guild id #{data[:guild_id]}, ignoring" unless (guild = @guilds[data[:guild_id]])

          user = if @users.has? data[:user][:id]
              @users[data[:user][:id]]
            else
              User.new(self, data[:user].update({ no_cache: true }))
            end

          dispatch(:guild_ban_add, guild, user)
        when "GUILD_BAN_REMOVE"
          return logger.warn "Unknown guild id #{data[:guild_id]}, ignoring" unless (guild = @guilds[data[:guild_id]])

          user = if @users.has? data[:user][:id]
              @users[data[:user][:id]]
            else
              User.new(self, data[:user].update({ no_cache: true }))
            end

          dispatch(:guild_ban_remove, guild, user)
        when "GUILD_EMOJIS_UPDATE"
          return logger.warn "Unknown guild id #{data[:guild_id]}, ignoring" unless (guild = @guilds[data[:guild_id]])

          before_emojis = guild.emojis.values.map(&:id).to_set
          data[:emojis].each do |emoji|
            guild.emojis[emoji[:id]] = CustomEmoji.new(self, guild, emoji)
          end
          deleted_emojis = before_emojis - guild.emojis.values.map(&:id).to_set
          deleted_emojis.each do |emoji|
            guild.emojis.delete(emoji)
          end
        when "GUILD_INTEGRATIONS_UPDATE"
          dispatch(:guild_integrations_update, @guilds[data[:guild_id]])
        when "INTEGRATION_CREATE"
          dispatch(:integration_create, Integration.new(self, data, data[:guild_id]))
        when "INTEGRATION_UPDATE"
          return logger.warn "Unknown guild id #{data[:guild_id]}, ignoring" unless (guild = @guilds[data[:guild_id]])

          integration = Integration.new(self, data, data[:guild_id])
          dispatch(:integration_update, integration)
        when "INTEGRATION_DELETE"
          return logger.warn "Unknown guild id #{data[:guild_id]}, ignoring" unless (guild = @guilds[data[:guild_id]])

          dispatch(:integration_delete, IntegrationDeleteEvent.new(self, data))
        when "WEBHOOKS_UPDATE"
          dispatch(:webhooks_update, WebhooksUpdateEvent.new(self, data))
        when "INVITE_CREATE"
          dispatch(:invite_create, Invite.new(self, data, true))
        when "INVITE_DELETE"
          dispatch(:invite_delete, InviteDeleteEvent.new(self, data))
        when "VOICE_STATE_UPDATE"
          return logger.warn "Unknown guild id #{data[:guild_id]}, ignoring" unless (guild = @guilds[data[:guild_id]])

          current = guild.voice_states[data[:user_id]]
          if current.nil?
            old = nil
            current = VoiceState.new(self, data)
            guild.voice_states[data[:user_id]] = current
          else
            guild.voice_states.remove(data[:user_id]) if data[:channel_id].nil?
            old = VoiceState.new(self, current.instance_variable_get(:@data))
            current.send(:_set_data, data)
          end
          dispatch(:voice_state_update, old, current)
          if old&.channel != current&.channel
            dispatch(:voice_channel_update, old, current)
            case [old&.channel.nil?, current&.channel.nil?]
            when [true, false]
              dispatch(:voice_channel_connect, current)
            when [false, true]
              dispatch(:voice_channel_disconnect, old)
            when [false, false]
              dispatch(:voice_channel_move, old, current)
            end
          end
          if old&.mute? != current&.mute?
            dispatch(:voice_mute_update, old, current)
            case [old&.mute?, current&.mute?]
            when [false, true]
              dispatch(:voice_mute_enable, current)
            when [true, false]
              dispatch(:voice_mute_disable, old)
            end
          end
          if old&.deaf? != current&.deaf?
            dispatch(:voice_deaf_update, old, current)
            case [old&.deaf?, current&.deaf?]
            when [false, true]
              dispatch(:voice_deaf_enable, current)
            when [true, false]
              dispatch(:voice_deaf_disable, old)
            end
          end
          if old&.self_mute? != current&.self_mute?
            dispatch(:voice_self_mute_update, old, current)
            case [old&.self_mute?, current&.self_mute?]
            when [false, true]
              dispatch(:voice_self_mute_enable, current)
            when [true, false]
              dispatch(:voice_self_mute_disable, old)
            end
          end
          if old&.self_deaf? != current&.self_deaf?
            dispatch(:voice_self_deaf_update, old, current)
            case [old&.self_deaf?, current&.self_deaf?]
            when [false, true]
              dispatch(:voice_self_deaf_enable, current)
            when [true, false]
              dispatch(:voice_self_deaf_disable, old)
            end
          end
          if old&.server_mute? != current&.server_mute?
            dispatch(:voice_server_mute_update, old, current)
            case [old&.server_mute?, current&.server_mute?]
            when [false, true]
              dispatch(:voice_server_mute_enable, current)
            when [true, false]
              dispatch(:voice_server_mute_disable, old)
            end
          end
          if old&.server_deaf? != current&.server_deaf?
            dispatch(:voice_server_deaf_update, old, current)
            case [old&.server_deaf?, current&.server_deaf?]
            when [false, true]
              dispatch(:voice_server_deaf_enable, current)
            when [true, false]
              dispatch(:voice_server_deaf_disable, old)
            end
          end
          if old&.video? != current&.video?
            dispatch(:voice_video_update, old, current)
            case [old&.video?, current&.video?]
            when [false, true]
              dispatch(:voice_video_start, current)
            when [true, false]
              dispatch(:voice_video_end, old)
            end
          end
          if old&.stream? != current&.stream?
            dispatch(:voice_stream_update, old, current)
            case [old&.stream?, current&.stream?]
            when [false, true]
              dispatch(:voice_stream_start, current)
            when [true, false]
              dispatch(:voice_stream_end, old)
            end
          end
        when "PRESENCE_UPDATE"
          return logger.warn "Unknown guild id #{data[:guild_id]}, ignoring" unless (guild = @guilds[data[:guild_id]])

          guild.presences[data[:user][:id]] = Presence.new(self, data)
        when "MESSAGE_UPDATE"
          if (message = @messages[data[:id]])
            before = Message.new(self, message.instance_variable_get(:@data), no_cache: true)
            message.send(:_set_data, message.instance_variable_get(:@data).merge(data))
          else
            before = nil
            message = nil
          end
          if data[:edited_timestamp].nil?
            if message.nil?
              nil
            elsif message.pinned?
              message.instance_variable_set(:@pinned, false)
            else
              message.instance_variable_set(:@pinned, true)
            end
            dispatch(:message_pin_update, MessagePinEvent.new(self, data, message))
          else
            dispatch(:message_update, MessageUpdateEvent.new(self, data, before, current))
          end
        when "MESSAGE_DELETE"
          message.instance_variable_set(:@deleted, true) if (message = @messages[data[:id]])

          dispatch(:message_delete_id, Snowflake.new(data[:id]), channels[data[:channel_id]],
                   data[:guild_id] && guilds[data[:guild_id]])
          dispatch(:message_delete, message, channels[data[:channel_id]], data[:guild_id] && guilds[data[:guild_id]])
        when "MESSAGE_DELETE_BULK"
          messages = []
          data[:ids].each do |id|
            if (message = @messages[id])
              message.instance_variable_set(:@deleted, true)
              messages.push(message)
            else
              messages.push(UnknownDeleteBulkMessage.new(self, id, data))
            end
          end
          dispatch(:message_delete_bulk, messages)
        when "MESSAGE_REACTION_ADD"
          if (target_message = @messages[data[:message_id]])
            if (target_reaction = target_message.reactions.find do |r|
              r.emoji.is_a?(UnicodeEmoji) ? r.emoji.value == data[:emoji][:name] : r.emoji.id == data[:emoji][:id]
            end)
              target_reaction.instance_variable_set(:@count, target_reaction.count + 1)
            else
              target_message.reactions << Reaction.new(
                target_message,
                {
                  count: 1,
                  me: @user.id == data[:user_id],
                  emoji: data[:emoji],
                }
              )
            end
          end
          dispatch(:reaction_add, ReactionEvent.new(self, data))
        when "MESSAGE_REACTION_REMOVE"
          if (target_message = @messages[data[:message_id]]) &&
             (target_reaction = target_message.reactions.find do |r|
               data[:emoji][:id].nil? ? r.emoji.name == data[:emoji][:name] : r.emoji.id == data[:emoji][:id]
             end)
            target_reaction.instance_variable_set(:@count, target_reaction.count - 1)
            target_message.reactions.delete(target_reaction) if target_reaction.count.zero?
          end
          dispatch(:reaction_remove, ReactionEvent.new(self, data))
        when "MESSAGE_REACTION_REMOVE_ALL"
          if (target_message = @messages[data[:message_id]])
            target_message.reactions = []
          end
          dispatch(:reaction_remove_all, ReactionRemoveAllEvent.new(self, data))
        when "MESSAGE_REACTION_REMOVE_EMOJI"
          if (target_message = @messages[data[:message_id]]) &&
             (target_reaction = target_message.reactions.find do |r|
               data[:emoji][:id].nil? ? r.name == data[:emoji][:name] : r.id == data[:emoji][:id]
             end)
            target_message.reactions.delete(target_reaction)
          end
          dispatch(:reaction_remove_emoji, ReactionRemoveEmojiEvent.new(self, data))
        when "TYPING_START"
          dispatch(:typing_start, TypingStartEvent.new(self, data))
        when "INTERACTION_CREATE"
          interaction = Interaction.make_interaction(self, data)
          dispatch(:interaction_create, interaction)

          dispatch(interaction.class.event_name, interaction)
        when "RESUMED"
          logger.info("Successfully resumed connection")
          @tasks << handle_heartbeat
          if shard
            dispatch(:shard_resumed, shard)
          else
            dispatch(:resumed)
          end
        when "GUILD_SCHEDULED_EVENT_CREATE"
          logger.warn("Unknown guild id #{data[:guild_id]}, ignoring") unless (guild = @guilds[data[:guild_id]])
          event = ScheduledEvent.new(self, data)
          guild.scheduled_events[data[:id]] = event
          dispatch(:scheduled_event_create, event)
        when "GUILD_SCHEDULED_EVENT_UPDATE"
          logger.warn("Unknown guild id #{data[:guild_id]}, ignoring") unless (guild = @guilds[data[:guild_id]])
          unless (event = guild.scheduled_events[data[:id]])
            logger.warn("Unknown scheduled event id #{data[:id]}, ignoring")
          end
          old = event.dup
          event.send(:_set_data, data)
          dispatch(:scheduled_event_update, old, event)
          if old.status == event.status
            dispatch(:scheduled_event_edit, old, event)
          else
            case event.status
            when :active
              dispatch(:scheduled_event_start, event)
            when :completed
              dispatch(:scheduled_event_end, event)
            end
          end
        when "GUILD_SCHEDULED_EVENT_DELETE"
          logger.warn("Unknown guild id #{data[:guild_id]}, ignoring") unless (guild = @guilds[data[:guild_id]])
          unless (event = guild.scheduled_events[data[:id]])
            logger.warn("Unknown scheduled event id #{data[:id]}, ignoring")
          end
          guild.scheduled_events.remove(data[:id])
          dispatch(:scheduled_event_delete, event)
          dispatch(:scheduled_event_cancel, event)
        when "GUILD_SCHEDULED_EVENT_USER_ADD"
          logger.warn("Unknown guild id #{data[:guild_id]}, ignoring") unless (guild = @guilds[data[:guild_id]])
          dispatch(:scheduled_event_user_add, ScheduledEventUserEvent.new(self, data))
        when "GUILD_SCHEDULED_EVENT_USER_REMOVE"
          logger.warn("Unknown guild id #{data[:guild_id]}, ignoring") unless (guild = @guilds[data[:guild_id]])
          dispatch(:scheduled_event_user_remove, ScheduledEventUserEvent.new(self, data))
        else
          if respond_to?("event_" + event_name.downcase)
            __send__("event_" + event_name.downcase, data)
          else
            logger.debug "Unhandled event: #{event_name}\n#{data.inspect}"
          end
        end
      end

      def ready
        Async do
          if @fetch_member
            logger.debug "Fetching members"
            barrier = Async::Barrier.new

            @guilds.each do |guild|
              barrier.async(parent: barrier) do
                guild.fetch_members
              end
            end
            barrier.wait
          end
          @ready = true

          if self.shard
            logger.info("Shard #{shard_id} is ready!")
            self.shard&.tap do |shard|
              if shard.next_shard
                dispatch(:shard_standby, shard)
                shard.next_shard.tap do |next_shard|
                  logger.debug("Starting shard #{next_shard.id}")
                  next_shard.start
                end
              else
                logger.info("All shards are ready!")
                dispatch(:standby)
              end
            end
          else
            logger.info("Client is ready!")
            dispatch(:standby)
          end
        end
      end
    end

    #
    # A class for connecting websocket with raw bytes data.
    # @private
    #
    class RawConnection < Async::WebSocket::Connection
      def initialize(*, **)
        super
        @closed = false
      end

      def inspect
        "<#{self.class.name} #{io.fileno}>"
      end

      def closed?
        @closed
      end

      def close
        super
        @closed = true
      rescue StandardError
        force_close
      end

      def force_close
        io.close
        @closed = true
      end

      def io
        @framer
          .instance_variable_get(:@stream)
          .instance_variable_get(:@io)
          .instance_variable_get(:@io)
          .instance_variable_get(:@io)
      end

      def parse(buffer)
        # noop
        buffer.to_s
      end

      def dump(object)
        # noop
        object.to_s
      end
    end
  end
end
