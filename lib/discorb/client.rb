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

require "async"
require "async/websocket/client"

$log = Logger.new(STDOUT)

module Discorb
  class Client
    attr_accessor :intents
    attr_reader :internet, :heartbeat_interval, :api_version, :user, :guilds, :token, :users

    def initialize(intents: nil)
      @intents = (intents or Intents.default())
      @events = {}
      @api_version = nil
      @user = nil
      @users = Discorb::Cache.new
      @guilds = Discorb::Cache.new
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
      Async do
        @events[event_name].each do |block|
          Async do |task|
            block[:block].call(task, *args)
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

    def inspect
      "#<Discorb::Client:0x#{self.object_id.to_s(16)} user=#{self.user}>"
    end

    private

    def connect_gateway(token)
      $log.info "Connecting to gateway."
      Async do |task|
        @internet = Internet.new(self)
        _, gateway_response = @internet.get("/gateway").wait
        gateway_url = gateway_response[:url]
        endpoint = Async::HTTP::Endpoint.parse(gateway_url + "?v=9&encoding=json", alpn_protocols: Async::HTTP::Protocol::HTTP11.names)
        Async::WebSocket::Client.connect(endpoint, headers: [["User-Agent", Discorb::USER_AGENT]]) do |connection|
          @connection = connection
          def @connection.inspect
            return "#<Connection:0x#{self.object_id.to_s(16)}>"
          end
          while message = @connection.read
            handle_gateway(message)
          end
        end
      end
    end

    def send_gateway(opcode, **value)
      @connection.write({ op: opcode, d: value })
      $log.debug "Sent message with opcode #{opcode}: #{value.to_json.gsub(@token, "[Token]")}"
    end

    def handle_gateway(payload)
      Async do
        data = payload[:d]
        $log.debug "Received message with opcode #{payload[:op]} from gateway: #{data}"
        case payload[:op]
        when 10
          @heartbeat_interval = data[:heartbeat_interval]
          handle_heartbeat(@heartbeat_interval)
          send_gateway(2, token: @token, intents: @intents.value, compress: false, properties: { "$os" => "windows", "$browser" => "discorb", "$device" => "discorb" })
        when 0
          handle_event(payload[:t], data)
        end
      end
    end

    def handle_heartbeat(interval)
      Async do |task|
        task.sleep(interval * rand)
        loop do
          send_gateway(1)
          $log.debug "Sent opcode 1."
          $log.debug "Waiting for heartbeat."
          task.sleep(interval / 1000.0)
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
        message = Discorb::Message.new(self, data)
        dispatch(:message, message)
      end
    end

    alias_method :add_event, :on
    alias_method :event, :on
  end
end
