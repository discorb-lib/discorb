# frozen_string_literal: true

require_relative "../common"

RSpec.describe Discorb::ApplicationCommand::Command::ChatInputCommand do
  let(:client) { Discorb::Client.new }

  it "registers chat input command" do
    client.slash "test", "test command description" do
      # do nothing
    end

    expect(client.commands.length).to eq 1
    expect(client.callable_commands.length).to eq 1
    expect(client.commands.first.to_hash).to eq(
      {
        default_member_permissions: nil,
        description: "test command description",
        description_localizations: {},
        dm_permission: true,
        name: "test",
        name_localizations: {},
        options: [],
      }
    )
  end

  it "registers chat group command" do
    client.slash_group "test_group", "test group description" do |group|
      group.slash "test", "test command description" do
        # do nothing
      end

      group.slash "test2", "test command description 2" do
        # do nothing
      end
    end

    expect(client.commands.length).to eq 1
    expect(client.callable_commands.length).to eq 2
    expect(client.commands.first.to_hash).to eq(
      {
        default_member_permissions: nil,
        description: "test group description",
        description_localizations: {},
        dm_permission: true,
        name: "test_group",
        name_localizations: {},
        options: [
          {
            description: "test command description",
            description_localizations: {},
            name: "test",
            name_localizations: {},
            options: [],
            type: 1,
          },
          {
            description: "test command description 2",
            description_localizations: {},
            name: "test2",
            name_localizations: {},
            options: [],
            type: 1,
          },
        ],
      }
    )
  end

  it "registers subcommand gruop" do
    client.slash_group "test_group", "test group description" do |group|
      group.group "test_subgroup", "test subcommand group description" do |subgroup|
        subgroup.slash "test", "test command description" do
          # do nothing
        end
      end
    end

    expect(client.commands.length).to eq 1
    expect(client.callable_commands.length).to eq 1
    expect(client.commands.first.to_hash).to eq(
      {
        default_member_permissions: nil,
        description: "test group description",
        description_localizations: {},
        dm_permission: true,
        name: "test_group",
        name_localizations: {},
        options: [
          {
            description: "test subcommand group description",
            description_localizations: {},
            name: "test_subgroup",
            name_localizations: {},
            options: [{
              description: "test command description",
              description_localizations: {},
              name: "test",
              name_localizations: {},
              options: [],
              type: 1,
            }],
            type: 2,
          },
        ],
      }
    )
  end

  {
    string: 3,
    str: 3,
    integer: 4,
    int: 4,
    boolean: 5,
    bool: 5,
    user: 6,
    channel: 7,
    role: 8,
    mentionable: 9,
    float: 10,
    attachment: 11,
  }.each do |type, value|
    it "registers chat input command with #{type} options" do
      client.slash "test", "test command description",
                   {
                     "arg1" => {
                       description: "test arg1 description",
                       type: type,
                     },
                   } do
        # do nothing
      end

      expect(client.commands.length).to eq 1
      expect(client.callable_commands.length).to eq 1
      expect(client.commands.first.to_hash).to eq(
        {
          default_member_permissions: nil,
          description: "test command description",
          description_localizations: {},
          dm_permission: true,
          name: "test",
          name_localizations: {},
          options: [
            {
              description: "test arg1 description",
              name: "arg1",
              name_localizations: {},
              required: true,
              type: value,
            },
          ],
        }
      )
    end
  end

  it "registers chat input command with optional options by :optional key" do
    client.slash "test", "test command description",
                 {
                   "arg1" => {
                     description: "test arg1 description",
                     type: :str,
                     optional: true,
                   },
                 } do
      # do nothing
    end

    expect(client.commands.length).to eq 1
    expect(client.callable_commands.length).to eq 1
    expect(client.commands.first.to_hash).to eq(
      {
        default_member_permissions: nil,
        description: "test command description",
        description_localizations: {},
        dm_permission: true,
        name: "test",
        name_localizations: {},
        options: [
          {
            description: "test arg1 description",
            name: "arg1",
            name_localizations: {},
            required: false,
            type: 3,
          },
        ],
      }
    )
  end

  it "registers chat input command with optional options by :required key" do
    client.slash "test", "test command description",
                 {
                   "arg1" => {
                     description: "test arg1 description",
                     type: :str,
                     required: false,
                   },
                 } do
      # do nothing
    end

    expect(client.commands.length).to eq 1
    expect(client.callable_commands.length).to eq 1
    expect(client.commands.first.to_hash).to eq(
      {
        default_member_permissions: nil,
        description: "test command description",
        description_localizations: {},
        dm_permission: true,
        name: "test",
        name_localizations: {},
        options: [
          {
            description: "test arg1 description",
            name: "arg1",
            name_localizations: {},
            required: false,
            type: 3,
          },
        ],
      }
    )
  end

  it "registers chat input command with choice" do
    client.slash "test", "test command description",
                 {
                   "arg1" => {
                     description: "test arg1 description",
                     type: :str,
                     choices: {
                       "choice 1" => "choice_1_value",
                       "choice 2" => "choice_2_value",
                     },
                   },
                 } do
      # do nothing
    end

    expect(client.commands.length).to eq 1
    expect(client.callable_commands.length).to eq 1
    expect(client.commands.first.to_hash).to eq(
      {
        default_member_permissions: nil,
        description: "test command description",
        description_localizations: {},
        dm_permission: true,
        name: "test",
        name_localizations: {},
        options: [
          {
            description: "test arg1 description",
            name: "arg1",
            name_localizations: {},
            required: true,
            type: 3,
            choices: [
              {
                name: "choice 1",
                value: "choice_1_value",
              },
              {
                name: "choice 2",
                value: "choice_2_value",
              },
            ],
          },
        ],
      }
    )
  end

  it "registers chat input command with localized name" do
    client.slash(
      {
        default: "test",
        ja: "test_ja",
      }, "test command description"
    ) do
      # do nothing
    end

    expect(client.commands.length).to eq 1
    expect(client.callable_commands.length).to eq 1
    expect(client.commands.first.to_hash).to eq(
      {
        default_member_permissions: nil,
        description: "test command description",
        description_localizations: {},
        dm_permission: true,
        name: "test",
        name_localizations: {
          "ja" => "test_ja",
        },
        options: [],
      }
    )
  end

  it "registers chat input command with localized description" do
    client.slash(
      "test",
      {
        default: "test description",
        ja: "test description_ja",
      }
    ) do
      # do nothing
    end

    expect(client.commands.length).to eq 1
    expect(client.callable_commands.length).to eq 1
    expect(client.commands.first.to_hash).to eq(
      {
        default_member_permissions: nil,
        description: "test description",
        description_localizations: {
          "ja" => "test description_ja",
        },
        dm_permission: true,
        name: "test",
        name_localizations: {},
        options: [],
      }
    )
  end

  it "registers chat input command with localized choice" do
    client.slash "test", "test command description",
                 {
                   "arg1" => {
                     description: "test arg1 description",
                     type: :str,
                     choices: {
                       "choice 1" => "choice_1_value",
                       "choice 2" => "choice_2_value",
                     },
                     choices_localizations: {
                       "choice 1" => {
                         default: "choice 1",
                         ja: "choice 1_ja",
                       },
                       "choice 2" => {
                         default: "choice 2",
                         ja: "choice 2_ja",
                       },
                     },
                   },
                 } do
      # do nothing
    end

    expect(client.commands.length).to eq 1
    expect(client.callable_commands.length).to eq 1
    expect(client.commands.first.to_hash).to eq(
      {
        default_member_permissions: nil,
        description: "test command description",
        description_localizations: {},
        dm_permission: true,
        name: "test",
        name_localizations: {},
        options: [
          {
            choices: [
              {
                name: "choice 1",
                name_localizations: {
                  "ja" => "choice 1_ja",
                },
                value: "choice_1_value",
              },
              {
                name: "choice 2",
                name_localizations: {
                  "ja" => "choice 2_ja",
                },
                value: "choice_2_value",
              },
            ],
            description: "test arg1 description",
            name: "arg1",
            name_localizations: {},
            required: true,
            type: 3,
          },
        ],
      }
    )
  end
end
