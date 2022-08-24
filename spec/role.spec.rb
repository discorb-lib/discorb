# frozen_string_literal: true

require_relative "./common"

RSpec.describe Discorb::Role do
  JSON.load_file("#{__dir__}/payloads/guild.json", symbolize_names: true)[
    :roles
  ].each do |role_data|
    let(:data) { role_data }
    let(:guild) do
      Discorb::Guild.new(
        client,
        JSON.load_file("#{__dir__}/payloads/guild.json", symbolize_names: true),
        false
      )
    end
    let(:role) { described_class.new(client, guild, data) }
    it "initializes successfully" do
      expect { role }.not_to raise_error
    end

    it "requests PATCH /guilds/:guild_id/roles/:id" do
      expect_request(
        :patch,
        "/guilds/#{guild.id}/roles/#{data[:id]}",
        body: {
          name: "new_name"
        },
        headers: {
          audit_log_reason: "reason"
        }
      ) { { code: 200, body: {} } }
      role.edit(name: "new_name", reason: "reason")
    end

    it "requests DELETE /guilds/:guild_id/roles/:id" do
      expect_request(
        :delete,
        "/guilds/#{guild.id}/roles/#{data[:id]}",
        headers: {
          audit_log_reason: "reason"
        }
      ) { { code: 204, body: {} } }
      role.delete(reason: "reason").wait
    end
  end
end
