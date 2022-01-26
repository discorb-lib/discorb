require "rspec"
require "discorb"
require "async"

Response = Struct.new(:code, :body)
RSpec.shared_context "mocks" do
  def expect_request(method, path, body: nil, headers: nil, &response)
    @next_request = {
      method: method,
      path: path,
      body: body,
      headers: headers,
    }
    @next_response = response
  end

  def expect_gateway_request(opcode, payload)
    @next_gateway_request = {
      opcode: opcode,
      payload: payload,
    }
  end

  let(:http) do
    http = double("Twitter client")
    allow(http).to receive(:request) { |path, headers|
      expect({
        method: path.method,
        path: path.url,
        body: nil,
        headers: headers,
      }).to eq(@next_request)
      Async do
        data = @next_response.call
        [Response.new(data[:code], data[:body]), data[:body]]
      end
    }

    http
  end
  let(:client) {
    client = Discorb::Client.new
    client.instance_variable_set(:@http, http)
    allow(client).to receive(:http).and_return(http)
    allow(client).to receive(:handle_heartbeat).and_return(Async { nil })

    allow(client).to receive(:send_gateway) { |opcode, **payload|
      expect({
        opcode: opcode,
        payload: payload,
      }).to eq(@next_gateway_request)
    }

    @next_gateway_request = {
      opcode: 2,
      payload: {
        compress: false, intents: Discorb::Intents.default.value,
        properties: { "$browser" => "discorb", "$device" => "discorb", "$os" => RUBY_PLATFORM },
        token: "Token",
      },
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
  }
end
