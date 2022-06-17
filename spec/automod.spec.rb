# frozen_string_literal: true

require_relative "common"

RSpec.describe Discorb::AutoModRule do
  let(:data) { JSON.load_file(__dir__ + "/payloads/automod.json", symbolize_names: true) }
  let(:rule) { described_class.new(client, data) }

  it "initializes successfully" do
    expect { described_class }.not_to raise_error
  end

  it "returns name" do
    expect(rule.name).to eq "Keyword Filter 1"
  end

  it "returns id" do
    expect(rule.id).to eq "969707018069872670"
  end

  it "returns if enabled" do
    expect(rule.enabled?).to be true
  end

  it "returns guild" do
    expect(rule.guild).to eq client.guilds[data[:guild_id]]
  end

  it "returns actions" do
    expect(rule.actions).to be_a Array
    expect(rule.actions.first).to be_a Discorb::AutoModRule::Action
  end

  it "returns exempt roles" do
    expect(rule.exempt_roles).to be_a Array
    expect(rule.exempt_roles.first).to be_a Discorb::Role
  end

  it "returns exempt channels" do
    expect(rule.exempt_channels).to be_a Array
    expect(rule.exempt_channels.first).to be_a Discorb::Channel
  end

  it "returns keyword filter" do
    expect(rule.keyword_filter).to eq ["cat*", "*dog", "*ana*", "i like javascript"]
  end
end
