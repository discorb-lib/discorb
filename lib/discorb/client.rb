require "pp"
require "json"
require "logger"
require_relative "intents"
require_relative "internet"
require_relative "common"
require_relative "message"
require_relative "user"
require_relative "cache"
require_relative "guild"
require_relative "error"
require_relative "log"

require "async"
require "async/websocket/client"

module Discorb
  class Client
    attr_accessor :intents
    attr_reader :internet, :heartbeat_interval, :api_version, :token, :allowed_mentions
    attr_reader :user, :guilds, :users, :channels, :emojis

    def initialize(allowed_mentions: nil, intents: nil, log: nil, colorize_log: false, log_level: :info)
      @allowed_mentions = allowed_mentions || AllowedMentions.new(everyone: true, roles: true, users: true)
      @intents = (intents or Intents.default())
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
    end

    def on(event_name, id: nil, &block)
      if @events[event_name] == nil
        @events[event_name] = []
      end
      @events[event_name] << { block: block, id: id }
    end

    def remove_event(event_name, id)
      @events[event_name].delete_if { |e| e[:id] == id }
    end

    def dispatch(event_name, *args)
      Async do |task|
        @log.debug "Dispatching event #{event_name}"
        @events[event_name].each do |block|
          task.async do |event_task|
            begin
              block[:block].call(event_task, *args)
              @log.debug "Dispatched proc with ID #{block[:id].inspect}"
            rescue Exception => e
              @log.error "Error occured while dispatching proc with ID #{block[:id].inspect}\n#{e.message}"
            end
          end
        end
      end
    end

    def run(token)
      @token = token
      self.connect_gateway(token)
    end

    def fetch_user(id)
      resp, data = self.internet.get("/users/#{id}").wait
      User.new(self, data)
    end

    def fetch_guild(id)
      resp, data = self.internet.get("/guilds/#{id}").wait
      Guild.new(self, data, false)
    end

    def update_presence(activity = nil, activities: nil, idle: nil, status: nil, afk: nil)
      payload = {}
      if activity != nil
        payload[:activities] = [activity.to_hash]
      elsif activities != nil
        payload[:activities] = activities.map(&:to_hash)
      end
      if idle != nil
        payload[:idle] = (Time.now.to_f * 1000).floor
      end
      if status != nil
        payload[:status] = status
      end
      if afk != nil
        payload[:afk] = afk
      end
      if @connection
        Async do |task|
          send_gateway(3, **payload)
        end
      else
        @identify_presence = payload
      end
    end

    def inspect
      "#<#{self.class} user=\"#{self.user}\">"
    end

    private

    def connect_gateway(token)
      @log.info "Connecting to gateway."
      Async do |task|
        @internet = Internet.new(self)
        _, gateway_response = @internet.get("/gateway").wait
        gateway_url = gateway_response[:url]
        endpoint = Async::HTTP::Endpoint.parse(gateway_url + "?v=9&encoding=json", alpn_protocols: Async::HTTP::Protocol::HTTP11.names)
        Async::WebSocket::Client.connect(endpoint, headers: [["User-Agent", Discorb::USER_AGENT]]) do |connection|
          @connection = connection
          def @connection.inspect
            return "#<Connection>"
          end
          while message = @connection.read
            handle_gateway(message)
          end
        end
      end
    end

    def send_gateway(opcode, **value)
      @connection.write({ op: opcode, d: value })
      @connection.flush
      @log.debug "Sent message with opcode #{opcode}: #{value.to_json.gsub(@token, "[Token]")}"
    end

    def handle_gateway(payload)
      Async do
        data = payload[:d]
        if payload[:s]
          @last_s = payload[:s]
        end
        @log.debug "Received message with opcode #{payload[:op]} from gateway: #{data}"
        case payload[:op]
        when 10
          @heartbeat_interval = data[:heartbeat_interval]
          handle_heartbeat(@heartbeat_interval)
          payload = {
            token: @token,
            intents: @intents.value,
            compress: false,
            properties: { "$os" => RUBY_PLATFORM, "$browser" => "discorb", "$device" => "discorb" },
          }
          if @identify_presence
            payload[:presence] = @identify_presence
          end
          send_gateway(2, **payload)
        when 9
          @connection.close
          @log.warn "Received opcode 9, closing connection"
          connect_gateway(@token)
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
          @log.debug "Sent opcode 1."
          @log.debug "Waiting for heartbeat."
          task.sleep(interval / 1000.0 - 1)
        end
      end
    end

    def handle_event(event_name, data)
      case event_name
      when "READY"
        @api_version = data[:v]
        @user = User.new(self, data[:user])
        @uncached_guilds = data[:guilds].map { |g| g[:id].to_i }
      when "GUILD_CREATE"
        guild = Guild.new(self, data, true)
        if @uncached_guilds.include?(guild.id)
          @uncached_guilds.delete(guild.id)
          if @uncached_guilds == []
            dispatch(:ready)
          end
        else
          dispatch(:guild_create, guild)
        end
      when "MESSAGE_CREATE"
        message = Message.new(self, data)
        dispatch(:message, message)
      end
    end

    alias_method :add_event, :on
    alias_method :event, :on
  end
end
