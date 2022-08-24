# frozen_string_literal: true

module Discorb
  module ApplicationCommand
    #
    # Module to handle application commands.
    #
    module Handler
      # @type instance: Discorb::Client

      #
      # Add new top-level command.
      #
      # @param [String, Hash{Symbol => String}] command_name Command name.
      #  If hash is passed, it must be a pair of Language code and Command name, and `:default` key is required.
      #  You can use `_` instead of `-` in language code.
      # @param [String, Hash{Symbol => String}] description Command description.
      #   If hash is passed, it must be a pair of Language code and Command description, and `:default` key is required.
      #  You can use `_` instead of `-` in language code.
      # @param [Hash{String => Hash{:description => String, :optional => Boolean, :type => Object}}] options
      #  Command options.
      #   The key is the option name, the value is a hash with the following keys:
      #
      #   | Key | Type | Description |
      #   | --- | --- | --- |
      #   | `:name_localizations` | Hash{Symbol => String} | Localizations of option name. |
      #   | `:description` | `String` \| `Hash{Symbol => String}` |
      #     Description of the option. If hash is passed, it must be a pair of Language code and description,
      #     and `:default` key is required. You can use `_` instead of `-` in language code. |
      #   | `:required` | Boolean(true | false) |
      #     Whether the argument is required. `optional` will be used if not specified. |
      #   | `:optional` | Boolean(true | false) |
      #     Whether the argument is optional. `required` will be used if not specified. |
      #   | `:type` | `Object` | Type of the option. |
      #   | `:choices` | `Hash{String => String, Integer, Float}` | Type of the option. |
      #   | `:choices_localizations` | `Hash{String => Hash{Symbol => String}}` |
      #      Localization of the choice. Key must be the name of a choice. |
      #   | `:default` | `Object` | Default value of the option. |
      #   | `:channel_types` | `Array<Class<Discorb::Channel>>` | Type of the channel option. |
      #   | `:autocomplete` | `Proc` | Autocomplete function. |
      #   | `:range` | `Range` | Range of the option. Only valid for numeric options. (`:int`, `:float`) |
      #   | `:length` | `Range` | Range of length of the option. Only valid for `:string`. |
      #
      # @param [Array<#to_s>, false, nil] guild_ids
      #  Guild IDs to set the command to. `false` to global command, `nil` to use default.
      # @param [Boolean] dm_permission Whether the command is available in DM.
      # @param [Discorb::Permission] default_permission The default permission of the command.
      # @param [Proc] block Command block.
      #
      # @return [Discorb::ApplicationCommand::Command::ChatInputCommand] Command object.
      #
      # @see file:docs/application_command.md#register-slash-command Application Comamnds: Register Slash Command
      # @see file:docs/cli/setup.md CLI: setup
      #
      def slash(
        command_name,
        description,
        options = {},
        guild_ids: nil,
        dm_permission: true,
        default_permission: nil,
        &block
      )
        command_name = { default: command_name } if command_name.is_a?(String)
        description = { default: description } if description.is_a?(String)
        command_name = ApplicationCommand.modify_localization_hash(command_name)
        description = ApplicationCommand.modify_localization_hash(description)
        command =
          Discorb::ApplicationCommand::Command::ChatInputCommand.new(
            command_name,
            description,
            options,
            guild_ids,
            block,
            1,
            nil,
            dm_permission,
            default_permission
          )
        @commands << command
        @callable_commands << command
        command
      end

      #
      # Add new command with group.
      #
      # @param [String, Hash{Symbol => String}] command_name Command name.
      # @param [String, Hash{Symbol => String}] description Command description.
      # @param [Array<#to_s>, false, nil] guild_ids
      #  Guild IDs to set the command to. `false` to global command, `nil` to use default.
      # @param [Boolean] dm_permission Whether the command is available in DM.
      # @param [Discorb::Permission] default_permission The default permission of the command.
      #
      # @yield Block to yield with the command.
      # @yieldparam [Discorb::ApplicationCommand::Command::GroupCommand] group Group command.
      #
      # @return [Discorb::ApplicationCommand::Command::GroupCommand] Command object.
      #
      # @see file:docs/application_command.md Application Commands
      # @see file:docs/cli/setup.md CLI: setup
      #
      def slash_group(
        command_name,
        description,
        guild_ids: nil,
        dm_permission: true,
        default_permission: nil
      )
        command_name = { default: command_name } if command_name.is_a?(String)
        description = { default: description } if description.is_a?(String)
        command_name = ApplicationCommand.modify_localization_hash(command_name)
        description = ApplicationCommand.modify_localization_hash(description)
        command =
          Discorb::ApplicationCommand::Command::GroupCommand.new(
            command_name,
            description,
            guild_ids,
            self,
            dm_permission,
            default_permission
          )
        yield command if block_given?
        @commands << command
        command
      end

      #
      # Add message context menu command.
      #
      # @param [String, Hash{Symbol => String}] command_name Command name.
      # @param [Array<#to_s>, false, nil] guild_ids
      #  Guild IDs to set the command to. `false` to global command, `nil` to use default.
      # @param [Boolean] dm_permission Whether the command is available in DM.
      # @param [Discorb::Permission] default_permission The default permission of the command.
      # @param [Proc] block Command block.
      # @yield [interaction, message] Block to execute.
      # @yieldparam [Discorb::CommandInteraction::UserMenuCommand] interaction Interaction object.
      # @yieldparam [Discorb::Message] message Message object.
      #
      # @return [Discorb::ApplicationCommand::Command] Command object.
      #
      def message_command(
        command_name,
        guild_ids: nil,
        dm_permission: true,
        default_permission: nil,
        &block
      )
        command_name = { default: command_name } if command_name.is_a?(String)
        command_name = ApplicationCommand.modify_localization_hash(command_name)
        command =
          Discorb::ApplicationCommand::Command.new(
            command_name,
            guild_ids,
            block,
            3,
            dm_permission,
            default_permission
          )
        @commands << command
        command
      end

      #
      # Add user context menu command.
      #
      # @param [String, Hash{Symbol => String}] command_name Command name.
      # @param [Array<#to_s>, false, nil] guild_ids
      #  Guild IDs to set the command to. `false` to global command, `nil` to use default.
      # @param [Boolean] dm_permission Whether the command is available in DM.
      # @param [Discorb::Permission] default_permission The default permission of the command.
      # @param [Proc] block Command block.
      # @yield [interaction, user] Block to execute.
      # @yieldparam [Discorb::CommandInteraction::UserMenuCommand] interaction Interaction object.
      # @yieldparam [Discorb::User] user User object.
      #
      # @return [Discorb::ApplicationCommand::Command] Command object.
      #
      def user_command(
        command_name,
        guild_ids: nil,
        dm_permission: true,
        default_permission: nil,
        &block
      )
        command_name = { default: command_name } if command_name.is_a?(String)
        command_name = ApplicationCommand.modify_localization_hash(command_name)
        command =
          Discorb::ApplicationCommand::Command.new(
            command_name,
            guild_ids,
            block,
            2,
            dm_permission,
            default_permission
          )
        @commands << command
        command
      end

      #
      # Setup commands.
      # @async
      # @see Client#initialize
      #
      # @param [String] token Bot token.
      # @param [Array<#to_s>, false, nil] guild_ids
      #  Guild IDs to use as default. If `false` is given, it will be global command.
      #
      # @note `token` parameter only required if you don't run client.
      #
      def setup_commands(token = nil, guild_ids: nil)
        Async do
          @token ||= token
          @http = HTTP.new(self)
          global_commands =
            @commands.select { |c| c.guild_ids == false or c.guild_ids == [] }
          local_commands =
            @commands.select do |c|
              c.guild_ids.is_a?(Array) and c.guild_ids.any?
            end
          default_commands = @commands.select { |c| c.guild_ids.nil? }
          if guild_ids.is_a?(Array)
            default_commands.each do |command|
              command.instance_variable_set(:@guild_ids, guild_ids)
            end
            local_commands += default_commands
          else
            global_commands += default_commands
          end
          final_guild_ids =
            local_commands.map(&:guild_ids).flatten.map(&:to_s).uniq
          app_info = fetch_application.wait
          unless global_commands.empty?
            @http.request(
              Route.new(
                "/applications/#{app_info.id}/commands",
                "//applications/:application_id/commands",
                :put
              ),
              global_commands.map(&:to_hash)
            ).wait
          end
          if ENV.fetch("DISCORB_CLI_FLAG", nil) == "setup"
            sputs "Registered commands for global:"
            global_commands.each do |command|
              iputs "- #{command.name["default"]}"
            end
          end
          unless final_guild_ids.empty?
            final_guild_ids.each do |guild_id|
              commands =
                local_commands.select { |c| c.guild_ids.include?(guild_id) }
              @http.request(
                Route.new(
                  "/applications/#{app_info.id}/guilds/#{guild_id}/commands",
                  "//applications/:application_id/guilds/:guild_id/commands",
                  :put
                ),
                commands.map(&:to_hash)
              ).wait
              sputs "Registered commands for #{guild_id}:"
              commands.each { |command| iputs "- #{command.name["default"]}" }
            end
          end
          @logger.info "Successfully setup commands"
        end
      end

      #
      # Claer commands in specified guilds.
      # @async
      # @see Client#initialize
      #
      # @param [String] token Bot token.
      # @param [Array<#to_s>, false, nil] guild_ids Guild IDs to clear.
      #
      # @note `token` parameter only required if you don't run client.
      #
      def clear_commands(token, guild_ids)
        Async do
          @token ||= token
          @http = HTTP.new(self)
          app_info = fetch_application.wait

          guild_ids.each do |guild_id|
            @http.request(
              Route.new(
                "/applications/#{app_info.id}/guilds/#{guild_id}/commands",
                "//applications/:application_id/guilds/:guild_id/commands",
                :put
              ),
              []
            ).wait
          end
          if ENV.fetch("DISCORB_CLI_FLAG", nil) == "setup"
            sputs "Cleared commands for #{guild_ids.length} guilds."
          end
        end
      end
    end
  end
end
