# frozen_string_literal: true
require "rspec"
require "discorb"
require "async"
require "async/rspec"

Response = Struct.new(:code, :body)
RSpec.shared_context "mocks" do # rubocop:disable RSpec/ContextWording
  def expect_request(method, path, body: nil, files: {}, headers: nil, &response)
    $next_request = {
      method: method,
      path: path,
      body: body,
      files: files,
      headers: headers,
    }
    $next_response = response
  end

  def expect_gateway_request(opcode, payload)
    $next_gateway_request.clear
    $next_gateway_request[:opcode] = opcode
    $next_gateway_request[:payload] = payload
  end

  let(:http) do
    http = instance_double("Discorb::HTTP")
    allow(http).to receive(:request) { |path, body, headers|
      body = nil if %i[get delete].include?(path.method)
      expect({
        method: path.method,
        path: path.url,
        body: body,
        files: {},
        headers: headers,
      }).to eq($next_request)
      Async do
        data = $next_response.call
        [Response.new(data[:code], data[:body]), data[:body]]
      end
    }
    allow(http).to receive(:multipart_request) { |path, body, files, headers|
      expect({
        method: path.method,
        path: path.url,
        body: body,
        files: files.to_h { |f| [f.name, f.read] },
        headers: headers,
      }).to eq($next_request)
      Async do
        data = $next_response.call
        [Response.new(data[:code], data[:body]), data[:body]]
      end
    }

    http
  end
  let(:client) do
    client = Discorb::Client.new
    client.instance_variable_set(:@http, http)
    client.instance_variable_set(:@connection, :dummy)
    allow(client).to receive(:http).and_return(http)
    allow(client).to receive(:handle_heartbeat).and_return(Async { nil })
    allow(client).to receive(:send_gateway) { |opcode, **payload|
      if $next_gateway_request
        expect({
          opcode: opcode,
          payload: payload,
        }).to eq($next_gateway_request)
      end
    }
    $next_gateway_request ||= {}

    $next_gateway_request[:opcode] = 2
    $next_gateway_request[:payload] = {
      compress: false, intents: Discorb::Intents.default.value,
      properties: { "$browser" => "discorb", "$device" => "discorb", "$os" => RUBY_PLATFORM },
      token: "Token",
    }

    class << client
      attr_accessor :next_gateway_request, :token
      public :handle_gateway
    end
    client.token = "Token"
    client.handle_gateway(
      JSON.parse(File.read("#{__dir__}/payloads/hello.json"), symbolize_names: true),
      false
    ).wait
    client.handle_gateway(
      JSON.parse(File.read("#{__dir__}/payloads/ready.json"), symbolize_names: true),
      false
    ).wait
    client.handle_gateway(
      JSON.parse(File.read("#{__dir__}/payloads/guild_create.json"), symbolize_names: true),
      false
    ).wait
    client
  end
end

RSpec.configure do |config|
  config.include_context "mocks"
  config.include_context Async::RSpec::Reactor
end
