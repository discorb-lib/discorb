require "json"

require_relative "consts"

require "async"
require "async/http/internet"
require "async/websocket/client"

module Discorb
  class Client
    attr_accessor :intents
    attr_reader :internet

    def initialize(intents: nil)
      @intents = intents
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
      Async do |task|
        @internet = Async::HTTP::Internet.new
        gateway_response = @internet.get(Discorb::API_BASE_URL + "/gateway")
        gateway_url = JSON[gateway_response.read]["url"]
        endpoint = Async::HTTP::Endpoint.parse(gateway_url + "?v=9&encoding=json")
        # endpoint = Async::HTTP::Endpoint.parse("wss://echo.websocket.org")
        Async::WebSocket::Client.connect(endpoint, headers: [["user-agent", "DiscordBot (https://github.com/sevenc-nanashi/discorb, 0.0.1)"]]) do |connection|
          while message = connection.read
            puts message.inspect
          end
        end
      end
    end
  end
end
