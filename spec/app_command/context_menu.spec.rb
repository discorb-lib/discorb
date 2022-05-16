# frozen_string_literal: true

require_relative "../common"

RSpec.describe Discorb::ApplicationCommand::Command do
  let(:client) { Discorb::Client.new }

  it "registers user command" do
    client.user_command "test" do
      # do nothing
    end

    expect(client.commands.length).to eq 1
    expect(client.commands.first.to_hash).to eq(
      {
        default_member_permissions: nil,
        dm_permission: true,
        name: "test",
        name_localizations: {},
        type: 2,
      }
    )
  end

  it "registers user command without dm permission" do
    client.user_command "test", dm_permission: false do
      # do nothing
    end

    expect(client.commands.length).to eq 1
    expect(client.commands.first.to_hash).to eq(
      {
        default_member_permissions: nil,
        dm_permission: false,
        name: "test",
        name_localizations: {},
        type: 2,
      }
    )
  end

  it "registers user command with admin permission" do
    client.user_command "test", default_permission: Discorb::Permission.from_keys(:administrator) do
      # do nothing
    end

    expect(client.commands.length).to eq 1
    expect(client.commands.first.to_hash).to eq(
      {
        default_member_permissions: "8",
        dm_permission: true,
        name: "test",
        name_localizations: {},
        type: 2,
      }
    )
  end

  it "registers message command" do
    client.message_command "test" do
      # do nothing
    end

    expect(client.commands.length).to eq 1
    expect(client.commands.first.to_hash).to eq(
      {
        default_member_permissions: nil,
        dm_permission: true,
        name: "test",
        name_localizations: {},
        type: 3,
      }
    )
  end

  it "registers message command without dm permission" do
    client.message_command "test", dm_permission: false do
      # do nothing
    end

    expect(client.commands.length).to eq 1
    expect(client.commands.first.to_hash).to eq(
      {
        default_member_permissions: nil,
        dm_permission: false,
        name: "test",
        name_localizations: {},
        type: 3,
      }
    )
  end

  it "registers message command with admin permission" do
    client.message_command "test", default_permission: Discorb::Permission.from_keys(:administrator) do
      # do nothing
    end

    expect(client.commands.length).to eq 1
    expect(client.commands.first.to_hash).to eq(
      {
        default_member_permissions: "8",
        dm_permission: true,
        name: "test",
        name_localizations: {},
        type: 3,
      }
    )
  end
end
