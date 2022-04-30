# frozen_string_literal: true

require_relative "../common"

[Discorb::TextChannel, Discorb::NewsChannel].each do |channel_class|
  RSpec.describe channel_class do
    let(:channel) do
      channel_class.new(client,
                        JSON.load_file(__dir__ + "/../payloads/channels/text_channel.json", symbolize_names: true))
    end

    it "initializes successfully" do
      expect { channel }.not_to raise_error
    end

    it "posts message" do
      expect_request(
        :post,
        "/channels/863581274916913196/messages",
        body: {
          allowed_mentions: {
            parse: %w[everyone roles users],
            replied_user: nil,
          },
          attachments: [],
          content: "msg",
          tts: false,
        },
      ) do
        {
          code: 200,
          body: JSON.load_file("#{__dir__}/../payloads/message.json", symbolize_names: true),
        }
      end
      expect(channel.post("msg").wait).to be_a Discorb::Message
    end

    it "creates new invite" do
      expect_request(
        :post,
        "/channels/863581274916913196/invites",
        body: {
          max_age: 0,
          max_uses: 1,
          temporary: false,
          unique: false,
        },
        headers: {
          audit_log_reason: nil,
        },
      ) do
        {
          code: 200,
          body: JSON.load_file("#{__dir__}/../payloads/invite.json", symbolize_names: true),
        }
      end
      expect(channel.create_invite(max_age: 0, max_uses: 1, temporary: false,
                                   unique: false).wait).to be_a Discorb::Invite
    end

    it "creates new thread" do
      expect_request(
        :post,
        "/channels/863581274916913196/threads",
        body: {
          auto_archive_duration: nil,
          name: "thread",
          rate_limit_per_user: nil,
          type: 11,
        },
        headers: {
          audit_log_reason: nil,
        },
      ) do
        {
          code: 200,
          body: JSON.load_file("#{__dir__}/../payloads/channels/thread_channel.json",
                               symbolize_names: true),

        }
      end
      expect(channel.create_thread("thread").wait).to be_a Discorb::ThreadChannel
    end

    Discorb::TextChannel::DEFAULT_AUTO_ARCHIVE_DURATION.each do |value, name|
      it "creates new thread with #{value} auto_archive_duration when passed #{name}" do
        expect_request(
          :post,
          "/channels/863581274916913196/threads",
          body: {
            auto_archive_duration: value,
            name: "thread",
            rate_limit_per_user: nil,
            type: 11,
          },
          headers: {
            audit_log_reason: nil,
          },
        ) do
          {
            code: 200,
            body: JSON.load_file("#{__dir__}/../payloads/channels/thread_channel.json", symbolize_names: true),
          }
        end
        expect(channel.create_thread("thread", auto_archive_duration: name).wait).to be_a Discorb::ThreadChannel
      end
    end

    describe "permissions" do
      it "returns { Discorb::Member, Discorb::Role => Discorb::PermissionOverwrite }" do
        expect(channel.permission_overwrites).to be_a Hash
        expect(channel.permission_overwrites.keys).to all(
          satisfy { |k| k.is_a?(Discorb::Role) || k.is_a?(Discorb::Member) },
        )
        expect(channel.permission_overwrites.values).to all(
          satisfy { |k| k.is_a?(Discorb::PermissionOverwrite) },
        )
      end
    end
  end
end
