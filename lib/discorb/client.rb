# frozen_string_literal: true

require 'pp'
require 'json'
require 'logger'
require_relative 'intents'
require_relative 'internet'
require_relative 'common'
require_relative 'channel'
require_relative 'message'
require_relative 'user'
require_relative 'cache'
require_relative 'guild'
require_relative 'error'
require_relative 'log'
require_relative 'event'
require_relative 'extension'

require 'async'
require 'async/websocket/client'

module Discorb
  class Client
    attr_accessor :intents
    attr_reader :internet, :heartbeat_interval, :api_version, :token, :allowed_mentions, :user, :guilds, :users,
                :channels, :emojis

    def initialize(allowed_mentions: nil, intents: nil, log: nil, colorize_log: false, log_level: :info)
      @allowed_mentions = allowed_mentions || AllowedMentions.new(everyone: true, roles: true, users: true)
      @intents = (intents or Intents.default)
      @events = {}
      @api_version = nil
      @log = Logger.new(log, colorize_log, log_level)
      @user = nil
      @users = Discorb::Cache.new
      @channels = Discorb::Cache.new
      @guilds = Discorb::Cache.new
      @emojis = Discorb::Cache.new
      @last_s = nil
      @identify_presence = nil
      @tasks = []
    end

    def on(event_name, id: nil, **discriminator, &block)
      @events[event_name] = [] if @events[event_name].nil?
      ne = Event.new(block, id, discriminator)
      @events[event_name] << ne
      ne
    end

    def remove_event(event_name, id)
      @events[event_name].delete_if { |e| e.id == id }
    end

    def dispatch(event_name, *args)
      Async do |_task|
        if @events[event_name].nil?
          @log.debug "Event #{event_name} doesn't have any proc, skipping"
          next
        end
        @log.debug "Dispatching event #{event_name}"
        @events[event_name].each do |block|
          lambda { |event_args|
            Async do |task|
              block.call(task, *event_args)
              @log.debug "Dispatched proc with ID #{block.id.inspect}"
            rescue StandardError, ScriptError => e
              if block.rescue.nil?
                @log.error "An error occurred while dispatching proc with ID #{block.id.inspect}\n#{e.full_message}"
              else
                begin
                  block.rescue.call(task, e, *args)
                rescue StandardError, ScriptError => e2
                  @log.error "An error occurred while dispatching rescue proc with ID #{block.id.inspect}\n#{e2.full_message}\nBy an error:\n#{e.full_message}"
                end
              end
            end
          }.call(args)
        end
      end
    end

    def run(token)
      @token = token
      connect_gateway(true)
    end

    def fetch_user(id)
      _resp, data = internet.get("/users/#{id}").wait
      User.new(self, data)
    end

    def fetch_channel(id)
      _resp, data = internet.get("/channels/#{id}").wait
      Channel.new(self, data)
    end

    def fetch_guild(id)
      _resp, data = internet.get("/guilds/#{id}").wait
      Guild.new(self, data, false)
    end

    def update_presence(activity = nil, activities: nil, idle: nil, status: nil, afk: nil)
      payload = {}
      if !activity.nil?
        payload[:activities] = [activity.to_hash]
      elsif !activities.nil?
        payload[:activities] = activities.map(&:to_hash)
      end
      payload[:idle] = (Time.now.to_f * 1000).floor unless idle.nil?
      payload[:status] = status unless status.nil?
      payload[:afk] = afk unless afk.nil?
      if @connection
        Async do |_task|
          send_gateway(3, **payload)
        end
      else
        @identify_presence = payload
      end
    end

    def inspect
      "#<#{self.class} user=\"#{user}\">"
    end

    def extend(mod)
      if mod.respond_to?(:events)
        mod.events.each do |name, events|
          @events[name] = [] if @events[name].nil?
          events.each do |event|
            @events[name] << event
          end
        end
        mod.client = self
      end
      super(mod)
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
        @uncached_guilds = data[:guilds].map { |g| g[:id].to_i }
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
        # TODO: Gateway: GUILD_ROLE_CREATE
      when 'GUILD_ROLE_UPDATE'
        # TODO: Gateway: GUILD_ROLE_UPDATE
      when 'GUILD_ROLE_DELETE'
        # TODO: Gateway: GUILD_ROLE_DELETE
      when 'CHANNEL_CREATE'
        # TODO: Gateway: CHANNEL_CREATE
      when 'CHANNEL_UPDATE'
        # TODO: Gateway: CHANNEL_UPDATE
      when 'CHANNEL_DELETE'
        # TODO: Gateway: CHANNEL_DELETE
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
      when 'THREAD_MEMBERS_UPDATE *'
        # TODO: Gateway: THREAD_MEMBERS_UPDATE *
      when 'STAGE_INSTANCE_CREATE'
        # TODO: Gateway: STAGE_INSTANCE_CREATE
      when 'STAGE_INSTANCE_UPDATE'
        # TODO: Gateway: STAGE_INSTANCE_UPDATE
      when 'STAGE_INSTANCE_DELETE'
        # TODO: Gateway: STAGE_INSTANCE_DELETE
      when 'GUILD_MEMBER_ADD'
        # TODO: Gateway: GUILD_MEMBER_ADD
      when 'GUILD_MEMBER_UPDATE'
        # TODO: Gateway: GUILD_MEMBER_UPDATE
      when 'GUILD_MEMBER_REMOVE'
        # TODO: Gateway: GUILD_MEMBER_REMOVE
      when 'GUILD_BAN_ADD'
        # TODO: Gateway: GUILD_BAN_ADD
      when 'GUILD_BAN_REMOVE'
        # TODO: Gateway: GUILD_BAN_REMOVE
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
        # TODO: Gateway: MESSAGE_REACTION_ADD
      when 'MESSAGE_REACTION_REMOVE'
        # TODO: Gateway: MESSAGE_REACTION_REMOVE
      when 'MESSAGE_REACTION_REMOVE_ALL'
        # TODO: Gateway: MESSAGE_REACTION_REMOVE_ALL
      when 'MESSAGE_REACTION_REMOVE_EMOJI'
        # TODO: Gateway: MESSAGE_REACTION_REMOVE_EMOJI
      when 'TYPING_START'
        # TODO: Gateway: TYPING_START
      else
        @log.warn "Unknown event: #{event_name}"
      end
    end

    alias add_event on
    alias event on
  end
end
