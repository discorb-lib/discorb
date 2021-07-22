# frozen_string_literal: true

module Discorb
  module GatewayHandler
    class GatewayEvent
      def initialize(data)
        @data = data
      end
    end

    class ReactionEvent < GatewayEvent
      attr_reader :data, :user_id, :channel_id, :message_id, :guild_id, :user, :channel, :guild, :message, :member_raw, :member, :emoji

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

        @user = client.users[data[:user_id]] if data.key?(:user_id)

        unless @guild.nil?
          @member = if data.key?(:member)
                      @guild.members[data[:member][:user][:id]] || Member.new(@client, @guild_id, data[:member][:user], data[:member])
                    else
                      @guild.members[data[:user_id]]
                    end
        end

        @message = client.messages[data[:message_id]]
        @emoji = data['id'].nil? ? UnicodeEmoji.new(data[:emoji][:name]) : PartialEmoji.new(data[:emoji])
      end

      def fetch_message(force: false)
        return @message if !force && @message

        Async do |_task|
          @channel.fetch_message(@message_id).wait
        end
      end
      alias member_id user_id
    end

    class ReactionRemoveAllEvent < GatewayEvent
      attr_reader :data, :guild_id, :channel_id, :message_id, :guild, :channel, :message

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
    end

    class ReactionRemoveEmojiEvent < GatewayEvent
      attr_reader :data, :guild_id, :channel_id, :message_id, :guild, :channel, :message, :emoji

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
    end

    private

    def connect_gateway(first)
      @log.info 'Connecting to gateway.'
      Async do |_task|
        @internet = Internet.new(self)
        @first = first
        _, gateway_response = @internet.get('/gateway').wait
        gateway_url = gateway_response[:url]
        endpoint = Async::HTTP::Endpoint.parse("#{gateway_url}?v=9&encoding=json",
                                               alpn_protocols: Async::HTTP::Protocol::HTTP11.names)
        begin
          Async::WebSocket::Client.connect(endpoint, headers: [['User-Agent', Discorb::USER_AGENT]]) do |connection|
            @connection = connection
            while (message = @connection.read)
              handle_gateway(message)
            end
          end
        rescue Protocol::WebSocket::ClosedError => e
          case e.message
          when 'Authentication failed.'
            @tasks.map(&:stop)
            raise ClientError.new('Authentication failed.'), cause: nil
          when 'Discord WebSocket requesting client reconnect.'
            @log.info 'Discord WebSocket requesting client reconnect.'
            connect_gateway(false)
          end
        end
      end
    end

    def send_gateway(opcode, **value)
      @connection.write({ op: opcode, d: value })
      @connection.flush
      @log.debug "Sent message with opcode #{opcode}: #{value.to_json.gsub(@token, '[Token]')}"
    end

    def handle_gateway(payload)
      Async do |task|
        data = payload[:d]
        @last_s = payload[:s] if payload[:s]
        @log.debug "Received message with opcode #{payload[:op]} from gateway: #{data}"
        case payload[:op]
        when 10
          @heartbeat_interval = data[:heartbeat_interval]
          @tasks << handle_heartbeat(@heartbeat_interval)
          if @first
            payload = {
              token: @token,
              intents: @intents.value,
              compress: false,
              properties: { '$os' => RUBY_PLATFORM, '$browser' => 'discorb', '$device' => 'discorb' }
            }
            payload[:presence] = @identify_presence if @identify_presence
            send_gateway(2, **payload)
          else
            payload = {
              token: @token,
              session_id: @session_id,
              seq: @last_s
            }
            send_gateway(6, **payload)
          end
        when 9
          @log.warn 'Received opcode 9, closed connection'
          if data
            @log.info 'Connection is resumable, reconnecting.'
            @connection.close
            connect_gateway(false)
          else
            @log.info 'Connection is not resumable, reconnecting with opcode 2.'
            task.sleep(2)
            @connection.close
            connect_gateway(true)
          end
        when 0
          handle_event(payload[:t], data)
        end
      end
    end

    def handle_heartbeat(interval)
      Async do |task|
        task.sleep((interval / 1000.0 - 1) * rand)
        loop do
          @connection.write({ op: 1, d: @last_s })
          @connection.flush
          @log.debug 'Sent opcode 1.'
          @log.debug 'Waiting for heartbeat.'
          task.sleep(interval / 1000.0 - 1)
        end
      end
    end

    def handle_event(event_name, data)
      case event_name
      when 'READY'
        @api_version = data[:v]
        @session_id = data[:session_id]
        @user = User.new(self, data[:user])
        @uncached_guilds = data[:guilds].map { |g| g[:id] }
      when 'GUILD_CREATE'
        if @uncached_guilds.include?(data[:id])
          guild = Guild.new(self, data, true)
          @uncached_guilds.delete(guild.id)
          dispatch(:ready) if @uncached_guilds == []
        elsif @guilds.has?(data[:id])
          @guilds[data[:id]]._set_from_hash(data)
          dispatch(:guild_available, guild)
        else
          guild = Guild.new(self, data, true)
          dispatch(:guild_join, guild)
        end
        dispatch(:guild_create, @guilds[data[:id]])
      when 'MESSAGE_CREATE'
        message = Message.new(self, data)
        dispatch(:message, message)
      when 'GUILD_UPDATE'
        if @guilds.has?(data[:id])
          @guilds[data[:id]]._set_from_hash(data, false)
          dispatch(:guild_update, @guilds[data[:id]])
        else
          @log.warn "Unknown guild id #{data[:id]}, ignoring"
        end
      when 'GUILD_DELETE'
        @guilds.delete(data[:id])
        dispatch(:guild_delete, @guilds[data[:id]])
      when 'GUILD_ROLE_CREATE'
        return @log.warn "Unknown guild id #{data[:guild_id]}, ignoring" unless @guilds.has? data[:guild_id]

        nr = Role.new(@client, @guilds[data[:guild_id]], data[:role])
        @guilds[data[:guild_id]].roles[data[:role][:id]] = nr
        dispatch(:role_create, nr)
      when 'GUILD_ROLE_UPDATE'
        return @log.warn "Unknown guild id #{data[:guild_id]}, ignoring" unless @guilds.has? data[:guild_id]
        return @log.warn "Unknown role id #{data[:role][:id]}, ignoring" unless @guilds[data[:guild_id]].roles.has?(data[:role][:id])

        current = @guilds[data[:guild_id]].roles[data[:role][:id]]
        before = Role.new(@client, @guilds[data[:guild_id]], current.instance_variable_get(:@_data).update({ no_cache: true }))
        current.send(:_set_data, data[:role])
        dispatch(:role_update, before, current)
      when 'GUILD_ROLE_DELETE'
        return @log.warn "Unknown guild id #{data[:guild_id]}, ignoring" unless @guilds.has? data[:guild_id]
        return @log.warn "Unknown role id #{data[:role_id]}, ignoring" unless @guilds[data[:guild_id]].roles.has?(data[:role_id])

        dispatch(:role_delete, @guilds[data[:guild_id]].roles.delete(data[:role_id]))
      when 'CHANNEL_CREATE'
        return @log.warn "Unknown guild id #{data[:guild_id]}, ignoring" unless @guilds.has? data[:guild_id]

        nc = Channel.make_channel(self, data)
        @guilds[data[:guild_id]].channels[data[:id]] = nc

        dispatch(:channel_create, nc)
      when 'CHANNEL_UPDATE'
        return @log.warn "Unknown guild id #{data[:guild_id]}, ignoring" unless @guilds.has? data[:guild_id]
        return @log.warn "Unknown channel id #{data[:id]}, ignoring" unless @guilds[data[:guild_id]].channels.has? data[:id]

        current = @guilds[data[:guild_id]].channels[data[:id]]
        before = Channel.make_channel(self, current.instance_variable_get(:@_data))
        current.send(:_set_data, data)
        dispatch(:channel_update, before, current)
      when 'CHANNEL_DELETE'
        return @log.warn "Unknown guild id #{data[:guild_id]}, ignoring" unless @guilds.has? data[:guild_id]
        return @log.warn "Unknown channel id #{data[:id]}, ignoring" unless @guilds[data[:guild_id]].channels.has? data[:id]

        dispatch(:channel_delete, @guilds[data[:guild_id]].channels.delete(data[:id]))
      when 'CHANNEL_PINS_UPDATE'
        # TODO: Gateway: CHANNEL_PINS_UPDATE
      when 'THREAD_CREATE'
        # TODO: Gateway: THREAD_CREATE
      when 'THREAD_UPDATE'
        # TODO: Gateway: THREAD_UPDATE
      when 'THREAD_DELETE'
        # TODO: Gateway: THREAD_DELETE
      when 'THREAD_LIST_SYNC'
        # TODO: Gateway: THREAD_LIST_SYNC
      when 'THREAD_MEMBER_UPDATE'
        # TODO: Gateway: THREAD_MEMBER_UPDATE
      when 'STAGE_INSTANCE_CREATE'
        # TODO: Gateway: STAGE_INSTANCE_CREATE
      when 'STAGE_INSTANCE_UPDATE'
        # TODO: Gateway: STAGE_INSTANCE_UPDATE
      when 'STAGE_INSTANCE_DELETE'
        # TODO: Gateway: STAGE_INSTANCE_DELETE
      when 'GUILD_MEMBER_ADD'
        return @log.warn "Unknown guild id #{data[:guild_id]}, ignoring" unless @guilds.has? data[:guild_id]

        nm = Member.new(self, data[:guild_id], data[:user].update({ no_cache: true }), data)
        @guilds[data[:guild_id]] = nm
        dispatch(:member_add, nm)
      when 'GUILD_MEMBER_UPDATE'
        return @log.warn "Unknown guild id #{data[:guild_id]}, ignoring" unless @guilds.has? data[:guild_id]
        return @log.warn "Unknown member id #{data[:id]}, ignoring" unless @guilds[data[:guild_id]].members.has?(data[:id])

        nm = @guilds[data[:guild_id]].members[data[:id]]
        old = Member.new(self, data[:guild_id], data[:user], data.update({ no_cache: true }))
        nm.send(:_set_data, data[:user], data)
        dispatch(:member_update, old, nm)
      when 'GUILD_MEMBER_REMOVE'
        return @log.warn "Unknown guild id #{data[:guild_id]}, ignoring" unless @guilds.has? data[:guild_id]
        return @log.warn "Unknown member id #{data[:id]}, ignoring" unless @guilds[data[:guild_id]].members.has?(data[:id])

        dispatch(:member_remove, @guilds[data[:guild_id]].members.delete(data[:id]))
      when 'GUILD_BAN_ADD'
        return @log.warn "Unknown guild id #{data[:guild_id]}, ignoring" unless @guilds.has? data[:guild_id]

        user = if @users.has? data[:user][:id]
                 @users[data[:user][:id]]
               else
                 User.new(self, data[:user].update({ no_cache: true }))
               end

        dispatch(:guild_ban_add, @guilds[data[:guild_id]], user)
      when 'GUILD_BAN_REMOVE'
        return @log.warn "Unknown guild id #{data[:guild_id]}, ignoring" unless @guilds.has? data[:guild_id]

        user = if @users.has? data[:user][:id]
                 @users[data[:user][:id]]
               else
                 User.new(self, data[:user].update({ no_cache: true }))
               end

        dispatch(:guild_ban_remove, @guilds[data[:guild_id]], user)
      when 'GUILD_EMOJIS_UPDATE'
        # TODO: Gateway: GUILD_EMOJIS_UPDATE
      when 'GUILD_INTEGRATIONS_UPDATE'
        # TODO: Gateway: GUILD_INTEGRATIONS_UPDATE
      when 'INTEGRATION_CREATE'
        # TODO: Gateway: INTEGRATION_CREATE
      when 'INTEGRATION_UPDATE'
        # TODO: Gateway: INTEGRATION_UPDATE
      when 'INTEGRATION_DELETE'
        # TODO: Gateway: INTEGRATION_DELETE
      when 'WEBHOOKS_UPDATE'
        # TODO: Gateway: WEBHOOKS_UPDATE
      when 'INVITE_CREATE'
        # TODO: Gateway: INVITE_CREATE
      when 'INVITE_DELETE'
        # TODO: Gateway: INVITE_DELETE
      when 'VOICE_STATE_UPDATE'
        # TODO: Gateway: VOICE_STATE_UPDATE
      when 'PRESENCE_UPDATE'
        # TODO: Gateway: PRESENCE_UPDATE
      when 'MESSAGE_UPDATE'
        # TODO: Gateway: MESSAGE_UPDATE
      when 'MESSAGE_DELETE'
        # TODO: Gateway: MESSAGE_DELETE
      when 'MESSAGE_DELETE_BULK'
        # TODO: Gateway: MESSAGE_DELETE_BULK
      when 'MESSAGE_REACTION_ADD'
        if (target_message = @messages[data[:message_id]])
          if (target_reaction = target_message.reactions.find { |r| r.id == data[:emoji][:id] })
            target_reaction.set_instance_variable(:@count, target_reaction.count + 1)
          else
            target_message.reactions << Reaction.new(
              {
                count: 1,
                me: @client.user.id == data[:user_id],
                emoji: data[:emoji]
              }
            )
          end
        end
        dispatch(:reaction_add, ReactionEvent.new(self, data))
      when 'MESSAGE_REACTION_REMOVE'
        if (target_message = @messages[data[:message_id]]) &&
           (target_reaction = target_message.reactions.find { |r| data[:emoji][:id].nil? ? r.name == data[:emoji][:name] : r.id == data[:emoji][:id] })
          target_reaction.set_instance_variable(:@count, target_reaction.count - 1)
          target_message.reactions.delete(target_reaction) if target_reaction.count.zero?
        end
        dispatch(:reaction_remove, ReactionEvent.new(self, data))
      when 'MESSAGE_REACTION_REMOVE_ALL'
        if (target_message = @messages[data[:message_id]])
          target_message.reactions = []
        end
        dispatch(:reaction_remove_all, ReactionRemoveAllEvent.new(self, data))
      when 'MESSAGE_REACTION_REMOVE_EMOJI'
        if (target_message = @messages[data[:message_id]]) &&
           (target_reaction = target_message.reactions.find { |r| data[:emoji][:id].nil? ? r.name == data[:emoji][:name] : r.id == data[:emoji][:id] })
          target_message.reactions.delete(target_reaction)
        end
        dispatch(:reaction_remove_emoji, ReactionRemoveEmojiEvent.new(data))
      when 'TYPING_START'
        # TODO: Gateway: TYPING_START
      else
        @log.warn "Unknown event: #{event_name}"
      end
    end
  end
end
