require "json"
require "logger"
require_relative "intents"
require_relative "consts"

require "async"
require "async/http/internet"
require "async/websocket/client"

$log = Logger.new(STDOUT)

module Discorb
  class Client
    attr_accessor :intents
    attr_reader :internet, :heartbeat_interval

    def initialize(intents: nil)
      @intents = (intents or Discorb::Intents.default())
      @events = Hash.new([])
    end

    def on(event_name, &block)
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
        Async::WebSocket::Client.connect(endpoint, headers: [["User-Agent", "DiscordBot (https://github.com/sevenc-nanashi/discorb 0.0.1) Ruby/#{RUBY_VERSION}"]]) do |connection|
          @connection = connection
          while message = @connection.read
            handle_gateway(message)
          end
        end
      end
    end

    def send_gateway(opcode, **value)
      @connection.write({ op: opcode, d: value }.to_json)
      @connection.flush
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
          send_gateway(2, token: "Bot " + @token, intents: @intents.value, properties: { "$os" => "windows", "$browser" => "discorb", "$device" => "discorb" })
        end
      end
    end

    def handle_heartbeat(interval)
      Async do |task|
        task.sleep(interval * rand)
        loop do
          @connection.write({ "op": 11 }.to_json)
          $log.debug "Sent opcode 11."
          $log.debug "Waiting for heartbeat."
          task.sleep(interval / 1000.0)
        end
      end
    end
  end
end
