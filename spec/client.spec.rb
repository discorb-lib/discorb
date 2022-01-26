require "rspec"
require "discorb"
require_relative "common"

RSpec.describe "Discorb::Client" do
  include_context "mocks"
  context "#run" do
    it "should connect to gateway" do
      client = Discorb::Client.new(log_level: :debug)
      allow(client).to receive(:http).and_return(http)
      allow(client).to receive(:handle_heartbeat).and_return(Async { nil })
      allow(client).to receive(:send_gateway) { |opcode, **payload|
        expect({
          opcode: opcode,
          payload: payload,
        }).to eq(@next_gateway_request)
      }
      class << client
        attr_accessor :next_gateway_request, :token
        public :handle_gateway
      end

      @next_gateway_request = {
        opcode: 2,
        payload: {
          compress: false, intents: Discorb::Intents.default.value,
          properties: { "$browser" => "discorb", "$device" => "discorb", "$os" => RUBY_PLATFORM },
          token: "Token",
        },
      }

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
      expect(client.instance_variable_get(:@ready)).to be true
    end
  end
  context "#fetch_xxx" do
    it "should request to GET /channels/:channel_id" do
      expect_request(:get, "/channels/875268362790400000") {
        {
          code: 200,
          body: {
            banner: nil,
            guild_id: "857373681096327180",
            id: "875268362790400000",
            last_message_id: "905198643630456892",
            name: "Test",
            nsfw: false,
            parent_id: nil,
            permission_overwrites: [],
            position: 10,
            rate_limit_per_user: 0,
            topic: nil,
            type: 0,
          },
        }
      }
      client.fetch_channel(875268362790400000).wait
    end
    it "should request to GET /users/:user_id" do
      expect_request(:get, "/users/686547120534454315") {
        {
          code: 200,
          body: {
            accent_color: 4763861,
            avatar: "a_8d1e355edd6a291d70e1cc75c0d31252",
            banner: nil,
            banner_color: "#48b0d5",
            discriminator: "7740",
            id: "686547120534454315",
            public_flags: 64,
            username: "Nanashi.",
          },
        }
      }
      client.fetch_user(686547120534454315).wait
    end
  end
end
