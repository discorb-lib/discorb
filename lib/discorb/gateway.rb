# frozen_string_literal: true

require 'time'

require_relative 'common'
require_relative 'invite'
require_relative 'voice_state'
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
        @emoji = data[:emoji][:id].nil? ? UnicodeEmoji.new(data[:emoji][:name]) : PartialEmoji.new(data[:emoji])
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

    class MessageUpdateEvent < GatewayEvent
      attr_reader :data, :before, :after, :id, :channel_id, :guild_id, :content, :timestamp, :mention_everyone, :mention_roles, :attachments, :embeds

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
        @attachments = data[:attachments].map { |a| Attachment.new(a) } if data.key?(:attachments)
        @embeds = data[:embeds] ? data[:embeds].map { |e| Embed.new(data: e) } : [] if data.key?(:embeds)
      end

      def channel
        @client.channels[@channel_id]
      end

      def guild
        @client.guilds[@guild_id]
      end

      def fetch_message
        Async do
          channel.fetch_message(@id).wait
        end
      end
    end

    class UnknownDeleteBulkMessage < GatewayEvent
      attr_reader :id

      def initialize(client, id, data)
        @client = client
        @id = id
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

    class InviteDeleteEvent < GatewayEvent
      attr_reader :code

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

    class GuildIntegrationsUpdateEvent < GatewayEvent
      def initialize(client, data)
        @client = client
        @data = data
        @guild_id = Snowflake.new(data[:guild_id])
      end

      def guild
        @client.guilds[@guild_id]
      end
    end

    class TypingStartEvent < GatewayEvent
      attr_reader :client, :channel_id, :guild_id, :user_id

      def initialize(client, data)
        @client = client
        @data = data
        @channel_id = Snowflake.new(data[:channel_id])
        @guild_id = Snowflake.new(data[:guild_id]) if data.key?(:guild_id)
        @user_id = Snowflake.new(data[:user_id])
        @timestamp = Time.at(data[:timestamp])
        @member = guild.members[@user_id] || Member.new(@client, @guild_id, @client.users[@user_id], data[:member]) if guild
      end

      def user
        @client.users[@user_id]
      end

      def channel
        @client.channels[@channel_id]
      end

      def guild
        @client.guilds[@guild_id]
      end
    end

    class MessagePinEvent < GatewayEvent
      attr_reader :message, :type

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
        @type = :unpinned
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
            @log.info 'Discord WebSocket requesting client reconnect'
            connect_gateway(false)
          end
        rescue EOFError
          connect_gateway(false)
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
            @log.info 'Connection is resumable, reconnecting'
            @connection.close
            connect_gateway(false)
          else
            @log.info 'Connection is not resumable, reconnecting with opcode 2'
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
          Guild.new(self, data, true)
          @uncached_guilds.delete(data[:id])
          if @uncached_guilds == []
            dispatch(:ready)
            @log.info('Guilds were cached')
          end
        elsif @guilds.has?(data[:id])
          @guilds[data[:id]].send(:_set_data, data)
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
          @guilds[data[:id]].send(:_set_data, data, false)
          dispatch(:guild_update, @guilds[data[:id]])
        else
          @log.warn "Unknown guild id #{data[:id]}, ignoring"
        end
      when 'GUILD_DELETE'
        return @log.warn "Unknown guild id #{data[:id]}, ignoring" unless (guild = @guilds.delete(data[:id]))

        dispatch(:guild_delete, guild)
        if guild.has?(:unavailable)
          dispatch(:guild_destroy, guild)
        else
          dispatch(:guild_leave, guild)
        end

      when 'GUILD_ROLE_CREATE'
        return @log.warn "Unknown guild id #{data[:guild_id]}, ignoring" unless (guild = @guilds[data[:guild_id]])

        nr = Role.new(@client, guild, data[:role])
        guild.roles[data[:role][:id]] = nr
        dispatch(:role_create, nr)
      when 'GUILD_ROLE_UPDATE'
        return @log.warn "Unknown guild id #{data[:guild_id]}, ignoring" unless (guild = @guilds[data[:guild_id]])
        return @log.warn "Unknown role id #{data[:role][:id]}, ignoring" unless guild.roles.has?(data[:role][:id])

        current = guild.roles[data[:role][:id]]
        before = Role.new(@client, guild, current.instance_variable_get(:@_data).update({ no_cache: true }))
        current.send(:_set_data, data[:role])
        dispatch(:role_update, before, current)
      when 'GUILD_ROLE_DELETE'
        return @log.warn "Unknown guild id #{data[:guild_id]}, ignoring" unless (guild = @guilds[data[:guild_id]])
        return @log.warn "Unknown role id #{data[:role_id]}, ignoring" unless (role = guild.roles.delete(data[:role_id]))

        dispatch(:role_delete, role)
      when 'CHANNEL_CREATE'
        return @log.warn "Unknown guild id #{data[:guild_id]}, ignoring" unless (guild = @guilds[data[:guild_id]])

        nc = Channel.make_channel(self, data)
        guild.channels[data[:id]] = nc

        dispatch(:channel_create, nc)
      when 'CHANNEL_UPDATE'
        return @log.warn "Unknown guild id #{data[:guild_id]}, ignoring" unless (guild = @guilds[data[:guild_id]])
        return @log.warn "Unknown channel id #{data[:id]}, ignoring" unless (current = guild.channels[data[:id]])

        before = Channel.make_channel(self, current.instance_variable_get(:@_data))
        current.send(:_set_data, data)
        dispatch(:channel_update, before, current)

      when 'CHANNEL_DELETE'
        return @log.warn "Unknown guild id #{data[:guild_id]}, ignoring" unless (guild = @guilds[data[:guild_id]])
        return @log.warn "Unknown channel id #{data[:id]}, ignoring" unless (channel = guild.channels.delete(data[:id]))

        dispatch(:channel_delete, channel)
      when 'CHANNEL_PINS_UPDATE'
        nil # do in MESSAGE_UPDATE
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
        instance = StageInstance.new(self, data)
        dispatch(:stage_instance_create, instance)
      when 'STAGE_INSTANCE_UPDATE'
        return @log.warn "Unknown channel id #{data[:channel_id]} , ignoring" unless (channel = @channels[data[:channel_id]])
        return @log.warn "Unknown stage instance id #{data[:id]}, ignoring" unless (instance = channel.stage_instances[data[:id]])

        old = StageInstance.new(self, instance.instance_variable_get(:@_data), no_cache: true)
        current.send(:_set_data, data)
        dispatch(:stage_instance_update, old, current)
      when 'STAGE_INSTANCE_DELETE'
        return @log.warn "Unknown channel id #{data[:channel_id]} , ignoring" unless (channel = @channels[data[:channel_id]])
        return @log.warn "Unknown stage instance id #{data[:id]}, ignoring" unless (instance = channel.stage_instances.delete(data[:id]))

        dispatch(:stage_instance_delete, instance)
      when 'GUILD_MEMBER_ADD'
        return @log.warn "Unknown guild id #{data[:guild_id]}, ignoring" unless (guild = @guilds[data[:guild_id]])

        nm = Member.new(self, data[:guild_id], data[:user].update({ no_cache: true }), data)
        guild.members[nm.id] = nm
        dispatch(:member_add, nm)
      when 'GUILD_MEMBER_UPDATE'
        return @log.warn "Unknown guild id #{data[:guild_id]}, ignoring" unless (guild = @guilds[data[:guild_id]])
        return @log.warn "Unknown member id #{data[:id]}, ignoring" unless (nm = guild.members[data[:id]])

        old = Member.new(self, data[:guild_id], data[:user], data.update({ no_cache: true }))
        nm.send(:_set_data, data[:user], data)
        dispatch(:member_update, old, nm)
      when 'GUILD_MEMBER_REMOVE'
        return @log.warn "Unknown guild id #{data[:guild_id]}, ignoring" unless (guild = @guilds[data[:guild_id]])
        return @log.warn "Unknown member id #{data[:id]}, ignoring" unless (member = guild.members.delete(data[:id]))

        dispatch(:member_remove, member)
      when 'GUILD_BAN_ADD'
        return @log.warn "Unknown guild id #{data[:guild_id]}, ignoring" unless (guild = @guilds[data[:guild_id]])

        user = if @users.has? data[:user][:id]
                 @users[data[:user][:id]]
               else
                 User.new(self, data[:user].update({ no_cache: true }))
               end

        dispatch(:guild_ban_add, guild, user)
      when 'GUILD_BAN_REMOVE'
        return @log.warn "Unknown guild id #{data[:guild_id]}, ignoring" unless (guild = @guilds[data[:guild_id]])

        user = if @users.has? data[:user][:id]
                 @users[data[:user][:id]]
               else
                 User.new(self, data[:user].update({ no_cache: true }))
               end

        dispatch(:guild_ban_remove, guild, user)
      when 'GUILD_EMOJIS_UPDATE'
        return @log.warn "Unknown guild id #{data[:guild_id]}, ignoring" unless (guild = @guilds[data[:guild_id]])

        before_emojis = guild.emojis.values.map(&:id).to_set
        data[:emojis].each do |emoji|
          guild.emojis[emoji[:id]] = CustomEmoji.new(self, guild, emoji)
        end
        deleted_emojis = before_emojis - guild.emojis.values.map(&:id).to_set
        deleted_emojis.each do |emoji|
          guild.emojis.delete(emoji)
        end
      when 'GUILD_INTEGRATIONS_UPDATE'
        dispatch(:guild_integrations_update, GuildIntegrationsUpdateEvent.new(self, data))
      when 'INTEGRATION_CREATE'
        dispatch(:integration_create, Integration.new(self, data, data[:guild_id]))
      when 'INTEGRATION_UPDATE'
        return @log.warn "Unknown guild id #{data[:guild_id]}, ignoring" unless (guild = @guilds[data[:guild_id]])
        return @log.warn "Unknown integration id #{data[:id]}, ignoring" unless (integration = guild.integrations[data[:id]])

        before = Integration.new(self, integration.instance_variable_get(:@_data), data[:guild_id], no_cache: true)
        integration.send(:_set_data, data)
        dispatch(:integration_update, before, integration)
      when 'INTEGRATION_DELETE'
        return @log.warn "Unknown guild id #{data[:guild_id]}, ignoring" unless (guild = @guilds[data[:guild_id]])
        return @log.warn "Unknown integration id #{data[:id]}, ignoring" unless (integration = guild.integrations.delete(data[:id]))

        dispatch(:integration_delete, integration)
      when 'WEBHOOKS_UPDATE'
        # TODO: Gateway: WEBHOOKS_UPDATE
      when 'INVITE_CREATE'
        dispatch(:invite_create, Invite.new(self, data, true))
      when 'INVITE_DELETE'
        dispatch(:invite_delete, InviteDeleteEvent.new(self, data))
      when 'VOICE_STATE_UPDATE'
        return @log.warn "Unknown guild id #{data[:guild_id]}, ignoring" unless (guild = @guilds[data[:guild_id]])

        current = guild.voice_states[data[:user_id]]
        if current.nil?
          old = nil
          current = VoiceState.new(self, data)
          guild.voice_states[data[:user_id]] = current
        else
          old = VoiceState.new(self, current.instance_variable_get(:@data))
          current.send(:_set_data, data)
        end
        dispatch(:voice_state_update, old, current)
        if old&.channel != current&.channel
          dispatch(:voice_channel_update, old, current)
          case [old&.channel, current&.channel]
          in [nil, _]
            dispatch(:voice_channel_connect, current)
          in [_, nil]
            dispatch(:voice_channel_disconnect, old)
          in _
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
          dispatch(:self_mute_update, old, current)
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
          dispatch(:server_mute_update, old, current)
          case [old&.server_mute?, current&.server_mute?]
          when [false, true]
            dispatch(:voice_server_mute_enable, current)
          when [true, false]
            dispatch(:voice_server_mute_disable, old)
          end
        end
        if old&.server_deaf? != current&.server_deaf?
          dispatch(:voice_server_deaf_enable, old, current)
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

      when 'PRESENCE_UPDATE'
        # TODO: Gateway: PRESENCE_UPDATE
      when 'MESSAGE_UPDATE'
        if (message = @messages[data[:id]])
          before = Message.new(self, message.instance_variable_get(:@_data), no_cache: true)
          message.send(:_set_data, message.instance_variable_get(:@_data).merge(data))
        else
          @log.info "Uncached message ID #{data[:id]}, ignoring"
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
      when 'MESSAGE_DELETE'
        return @log.info "Uncached message ID #{data[:id]}, ignoring" unless (message = @messages[data[:id]])

        message.instance_variable_set(:@deleted, true)
        dispatch(:message_delete, message)
      when 'MESSAGE_DELETE_BULK'
        messages = []
        data[:ids].each do |id|
          if (message = @messages[id])
            message.instance_variable_set(:@deleted, true)
            messages.push(message)
          else
            messages.push(UnknownDeleteBulkMessage.new(self, id))
          end
        end
        dispatch(:message_delete_bulk, messages)
      when 'MESSAGE_REACTION_ADD'
        if (target_message = @messages[data[:message_id]])
          if (target_reaction = target_message.reactions.find { |r| r.id == data[:emoji][:id] })
            target_reaction.set_instance_variable(:@count, target_reaction.count + 1)
          else
            target_message.reactions << Reaction.new(
              self,
              {
                count: 1,
                me: @user.id == data[:user_id],
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
        dispatch(:typing_start, TypingStartEvent.new(self, data))
      else
        @log.warn "Unknown event: #{event_name}"
      end
    end
  end
end
