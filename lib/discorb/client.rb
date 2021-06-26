require "pp"
require "json"
require "logger"
require_relative "intents"
require_relative "common"
require_relative "user"

require "async"
require "async/http/internet"
require "async/websocket/client"

$log = Logger.new(STDOUT, level: Logger::Severity::INFO)

module Discorb
  class Client
    attr_accessor :intents
    attr_reader :internet, :heartbeat_interval, :api_version, :user

    def initialize(intents: nil)
      @intents = (intents or Discorb::Intents.default())
      @events = {}
      @api_version = nil
      @user = nil
    end

    def on(event_name, &block)
      if @events[event_name] == nil
        @events[event_name] = []
      end
      @events[event_name] << block
    end

    def dispatch(event_name, *args)
      Async do
        @events[event_name].each do |block|
          Async do |task|
            block.call(task, *args)
          end
        end
      end
    end

    def run(token)
      @token = token
      self.connect_gateway(token)
    end

    private

    def connect_gateway(token)
      $log.info "Connecting to gateway."
      Async do |task|
        @internet = Async::HTTP::Internet.new
        gateway_response = @internet.get(Discorb::API_BASE_URL + "/gateway")
        gateway_url = JSON[gateway_response.read]["url"]
        endpoint = Async::HTTP::Endpoint.parse(gateway_url + "?v=9&encoding=json", alpn_protocols: Async::HTTP::Protocol::HTTP11.names)
        Async::WebSocket::Client.connect(endpoint, headers: [["User-Agent", Discorb::USER_AGENT]]) do |connection|
          @connection = connection
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
        $log.debug "Received message with opcode #{payload[:op]} from gateway: #{payload}"
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
      pp event_name, data
      case event_name
      when "READY"
        @api_version = data[:v]
        @user = User.new(self, data[:user])
        @uncached_guilds = data[:guilds].map { |g| g[:id] }
        dispatch(:ready)
      when "GUILD_CREATE"
        if @uncached_guilds.include?(data[:id])
          # TODO: サーバーキャッシュ
        else
          # TODO: サーバー参加処理
        end
      end
    end
  end
end
