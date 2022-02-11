require "rspec"
require "discorb"
require "async/rspec"
require_relative "common"

RSpec.describe "Discorb::Client" do
  include_context "mocks"
  include_context Async::RSpec::Reactor
  context "gateway" do
    it "connects to gateway" do
      client = Discorb::Client.new(log_level: :debug)
      allow(client).to receive(:http).and_return(http)
      allow(client).to receive(:handle_heartbeat).and_return(Async { nil })
      allow(client).to receive(:send_gateway) { |opcode, **payload|
        expect({
          opcode: opcode,
          payload: payload,
        }).to eq($next_gateway_request)
      }
      class << client
        attr_accessor :next_gateway_request, :token
        public :handle_gateway
      end

      $next_gateway_request = {
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
    it "sends valid payload to change presence" do
      client  # initialize client
      %i[online idle dnd offline].each do |status|
        expect_gateway_request(
          3,
          activities: [],
          status: status,
          afk: nil,
          since: nil,

        )
        client.change_presence(status: status).wait
      end
    end
  end
  context "#fetch_xxx" do
    it "requests to GET /guilds/:guild_id" do
      expect_request(:get, "/guilds/863581274916913193") {
        {
          code: 200,
          body: File.read("#{__dir__}/payloads/guild.json").then { JSON.parse(_1, symbolize_names: true) },
        }
      }
      client.fetch_guild(863581274916913193).wait
    end
    it "requests to GET /channels/:channel_id" do
      expect_request(:get, "/channels/863581274916913196") {
        {
          code: 200,
          body: File.read("#{__dir__}/payloads/channels/text_channel.json").then { JSON.parse(_1, symbolize_names: true) },
        }
      }
      client.fetch_channel(863581274916913196).wait
    end
    it "requests to GET /users/:user_id" do
      expect_request(:get, "/users/686547120534454315") {
        {
          code: 200,
          body: File.read("#{__dir__}/payloads/users/user.json").then { JSON.parse(_1, symbolize_names: true) },
        }
      }
      client.fetch_user(686547120534454315).wait
    end
  end
  context "events" do
    it "registers an event handler" do
      cond = Async::Condition.new
      client.on :test do
        cond.signal true
      end
      Async do
        sleep 0.1
        client.dispatch :test
      end
      expect(cond.wait).to be true
    end
    it "registers an event handler that will be run once" do
      timeouted = false
      cond = Async::Condition.new
      client.once :test do
        cond.signal true
      end
      client.dispatch :test
      Async do |task|
        task.with_timeout(0.1) do
          cond.wait
        rescue Async::TimeoutError
          timeouted = true
        end
      end.wait
      expect(timeouted).to be true
    end
    it "returns the task that stops until the event is fired" do
      task = client.event_lock(:event)
      Async do
        client.dispatch(:event, 1)
      end
      expect(task.wait).to eq 1
    end
    it "raises timeout error" do
      expect {
        client.event_lock(:event, 0.1).wait
      }.to raise_error(Discorb::TimeoutError)
    end
  end
end
