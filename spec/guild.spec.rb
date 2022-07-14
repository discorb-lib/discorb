# frozen_string_literal: true

require_relative "common"

RSpec.describe Discorb::Guild do
  let(:data) { JSON.load_file(__dir__ + "/payloads/guild.json", symbolize_names: true) }
  let(:guild) { described_class.new(client, data, false) }

  it "initializes successfully" do
    expect { guild }.not_to raise_error
  end

  it "requests to DELETE /users/@me/guilds/:guild_id" do
    expect_request(:delete, "/users/@me/guilds/#{guild.id}") do
      {
        code: 204,
        body: {},
      }
    end
    guild.leave.wait
  end

  it "requests to POST /guilds/:guild_id/channels with text channel payload" do
    expect_request(
      :post,
      "/guilds/#{guild.id}/channels",
      body: {
        type: Discorb::TextChannel.channel_type,
        name: "new_channel",
      },
      headers: { audit_log_reason: "reason" },
    ) do
      {
        code: 200,
        body: JSON.load_file(__dir__ + "/payloads/channels/text_channel.json", symbolize_names: true),
      }
    end
    guild.create_text_channel("new_channel", reason: "reason").wait
  end

  it "requests to POST /guilds/:guild_id/channels with voice channel payload" do
    expect_request(
      :post,
      "/guilds/#{guild.id}/channels",
      body: {
        type: Discorb::VoiceChannel.channel_type,
        name: "new_channel",
        bitrate: 64000,
      },
      headers: { audit_log_reason: "reason" },
    ) do
      {
        code: 200,
        body: JSON.load_file(__dir__ + "/payloads/channels/voice_channel.json", symbolize_names: true),
      }
    end
    guild.create_voice_channel("new_channel", reason: "reason").wait
  end
end
