# frozen_string_literal: true

module Discorb
  #
  # Handles application commands.
  #
  module ApplicationCommand
    #
    # Module to handle application commands.
    #
    module Handler
      #
      # Add new top-level command.
      #
      # @param [String] command_name Command name.
      # @param [String] description Command description.
      # @param [Hash{String => Hash{:description => String, :optional => Boolean, :type => Object}}] options Command options.
      #   The key is the option name, the value is a hash with the following keys:
      #
      #   | Key | Type | Description |
      #   | --- | --- | --- |
      #   | `:description` | `String` | Description of the option. |
      #   | `:optional` | `Boolean` | Whether the option is optional or not. |
      #   | `:type` | `Object` | Type of the option. |
      #   | `:choice` | `Hash{String => String, Integer, Float}` | Type of the option. |
      #
      # @param [Array<#to_s>, false, nil] guild_ids Guild IDs to set the command to. `false` to global command, `nil` to use default.
      # @param [Proc] block Command block.
      #
      # @return [Discorb::ApplicationCommand::Command::SlashCommand] Command object.
      #
      # @see file:docs/application_command.md#register-slash-command
      # @see file:docs/cli/setup.md
      #
      def slash(command_name, description, options = {}, guild_ids: nil, &block)
        command = Discorb::ApplicationCommand::Command::SlashCommand.new(command_name, description, options, guild_ids, block, 1, "")
        @commands << command
        @bottom_commands << command
        command
      end

      #
      # Add new command with group.
      #
      # @param [String] command_name Command name.
      # @param [String] description Command description.
      # @param [Array<#to_s>, false, nil] guild_ids Guild IDs to set the command to. `false` to global command, `nil` to use default.
      #
      # @yield Block to yield with the command.
      # @yieldparam [Discorb::ApplicationCommand::Command::GroupCommand] group Group command.
      #
      # @return [Discorb::ApplicationCommand::Command::GroupCommand] Command object.
      #
      # @see file:docs/slash_command.md
      # @see file:docs/cli/setup.md
      #
      def slash_group(command_name, description, guild_ids: nil, &block)
        command = Discorb::ApplicationCommand::Command::GroupCommand.new(command_name, description, guild_ids, nil, self)
        command.yield_self(&block) if block_given?
        @commands << command
        command
      end

      #
      # Add message context menu command.
      #
      # @param [String] command_name Command name.
      # @param [Array<#to_s>, false, nil] guild_ids Guild IDs to set the command to. `false` to global command, `nil` to use default.
      # @param [Proc] block Command block.
      # @yield [interaction, message] Block to execute.
      # @yieldparam [Discorb::ApplicationCommandInteraction::UserMenuCommand] interaction Interaction object.
      # @yieldparam [Discorb::Message] message Message object.
      #
      # @return [Discorb::ApplicationCommand::Command] Command object.
      #
      def message_command(command_name, guild_ids: nil, &block)
        command = Discorb::ApplicationCommand::Command.new(command_name, guild_ids, block, 3)
        @commands << command
        command
      end

      #
      # Add user context menu command.
      #
      # @param [String] command_name Command name.
      # @param [Array<#to_s>, false, nil] guild_ids Guild IDs to set the command to. `false` to global command, `nil` to use default.
      # @param [Proc] block Command block.
      # @yield [interaction, user] Block to execute.
      # @yieldparam [Discorb::ApplicationCommandInteraction::UserMenuCommand] interaction Interaction object.
      # @yieldparam [Discorb::User] user User object.
      #
      # @return [Discorb::ApplicationCommand::Command] Command object.
      #
      def user_command(command_name, guild_ids: nil, &block)
        command = Discorb::ApplicationCommand::Command.new(command_name, guild_ids, block, 2)
        @commands << command
        command
      end

      #
      # Setup commands.
      # @see Client#initialize
      #
      # @param [String] token Bot token.
      # @param [Array<#to_s>, false, nil] guild_ids Guild IDs to use as default. If `false` is given, it will be global command.
      #
      # @note `token` parameter only required if you don't run client.
      #
      def setup_commands(token = nil, guild_ids: nil)
        Async do
          @token ||= token
          @http = HTTP.new(self)
          global_commands = @commands.select { |c| c.guild_ids == false or c.guild_ids == [] }
          local_commands = @commands.select { |c| c.guild_ids.is_a?(Array) and c.guild_ids.any? }
          default_commands = @commands.select { |c| c.guild_ids.nil? }
          if guild_ids.is_a?(Array)
            default_commands.each do |command|
              command.instance_variable_set(:@guild_ids, guild_ids)
            end
            local_commands += default_commands
          else
            global_commands += default_commands
          end
          final_guild_ids = local_commands.map(&:guild_ids).flatten.map(&:to_s).uniq
          app_info = fetch_application.wait
          http.put("/applications/#{app_info.id}/commands", global_commands.map(&:to_hash)).wait unless global_commands.empty?
          final_guild_ids.each do |guild_id|
            commands = local_commands.select { |c| c.guild_ids.include?(guild_id) }
            http.put("/applications/#{app_info.id}/guilds/#{guild_id}/commands", commands.map(&:to_hash)).wait
          end unless final_guild_ids.empty?
          @log.info "Successfully setup commands"
        end
      end
    end

    #
    # Represents a application command.
    # @abstract
    #
    class Command < DiscordModel
      # @return [String] The name of the command.
      attr_reader :name
      # @return [Array<#to_s>] The guild ids that the command is enabled in.
      attr_reader :guild_ids
      # @return [Proc] The block of the command.
      attr_reader :block
      # @return [:chat_input, :user, :message] The type of the command.
      attr_reader :type
      # @return [Integer] The raw type of the command.
      attr_reader :type_raw
      # @return [Discorb::Dictionary{Discorb::Snowflake, :global => Discorb::Snowflake}] The ID mapping.
      attr_reader :id_map

      @types = {
        1 => :chat_input,
        2 => :user,
        3 => :message,
      }.freeze

      # @!visibility private
      def initialize(name, guild_ids, block, type)
        @name = name
        @guild_ids = guild_ids&.map(&:to_s)
        @block = block
        @raw_type = type
        @type = Discorb::ApplicationCommand::Command.types[type]
        @type_raw = type
        @id_map = Discorb::Dictionary.new
      end

      # @!visibility private
      def to_hash
        {
          name: @name,
          default_permission: @default_permission,
          type: @type_raw,
        }
      end

      #
      # Represents the slash command.
      #
      class SlashCommand < Command
        # @return [String] The description of the command.
        attr_reader :description
        # @return [Hash{String => Hash}] The options of the command.
        attr_reader :options

        # @!visibility private
        def initialize(name, description, options, guild_ids, block, type, parent)
          super(name, guild_ids, block, type)
          @description = description
          @options = options
          @id = nil
          @parent = parent
          @id_map = Discorb::Dictionary.new
        end

        #
        # Returns the commands name.
        #
        # @return [String] The name of the command.
        #
        def to_s
          (@parent + " " + @name).strip
        end

        # @!visibility private
        def to_hash
          options_payload = options.map do |name, value|
            ret = {
              type: case value[:type]
              when String, :string, :str
                3
              when Integer, :integer, :int
                4
              when TrueClass, FalseClass, :boolean, :bool
                5
              when Discorb::User, Discorb::Member, :user, :member
                6
              when Discorb::Channel, :channel
                7
              when Discorb::Role, :role
                8
              when :mentionable
                9
              when Float, :float
                10
              else
                raise ArgumentError, "Invalid option type: #{value[:type]}"
              end,
              name: name,
              description: value[:description],
              required: !value[:optional],
            }
            if value[:choices]
              ret[:choices] = value[:choices].map { |t| { name: t[0], value: t[1] } }
            end
            ret
          end
          {
            name: @name,
            default_permission: true,
            description: @description,
            options: options_payload,
          }
        end
      end

      #
      # Represents the command with subcommands.
      #
      class GroupCommand < Command
        # @return [Array<Discorb::ApplicationCommand::Command::SlashCommand, Discorb::ApplicationCommand::Command::SubcommandGroup>] The subcommands of the command.
        attr_reader :commands
        # @return [String] The description of the command.
        attr_reader :description

        # @!visibility private
        def initialize(name, description, guild_ids, type, client)
          super(name, guild_ids, block, type)
          @description = description
          @commands = []
          @client = client
          @id_map = Discorb::Dictionary.new
        end

        #
        # Add new subcommand.
        #
        # @param (see Discorb::ApplicationCommand::Handler#slash)
        # @return [Discorb::ApplicationCommand::Command::SlashCommand] The added subcommand.
        #
        def slash(command_name, description, options = {}, &block)
          command = Discorb::ApplicationCommand::Command::SlashCommand.new(command_name, description, options, [], block, 1, @name)
          @client.bottom_commands << command
          @commands << command
          command
        end

        #
        # Add new subcommand group.
        #
        # @param [String] command_name Group name.
        # @param [String] description Group description.
        #
        # @yield Block to yield with the command.
        # @yieldparam [Discorb::ApplicationCommand::Command::SubcommandGroup] group Group command.
        #
        # @return [Discorb::ApplicationCommand::Command::SubcommandGroup] Command object.
        #
        # @see file:docs/slash_command.md
        #
        def group(command_name, description, &block)
          command = Discorb::ApplicationCommand::Command::SubcommandGroup.new(command_name, description, @name, @client)
          command.yield_self(&block) if block_given?
          @commands << command
          command
        end

        #
        # Returns the command name.
        #
        # @return [String] The command name.
        #
        def to_s
          @name
        end

        # @!visibility private
        def to_hash
          options_payload = @commands.map do |command|
            if command.is_a?(SlashCommand)
              {
                name: command.name,
                description: command.description,
                default_permission: true,
                type: 1,
                options: command.to_hash[:options],
              }
            else
              {
                name: command.name,
                description: command.description,
                default_permission: true,
                type: 2,
                options: command.commands.map { |c| c.to_hash.merge(type: 1) },
              }
            end
          end

          {
            name: @name,
            default_permission: @enabled,
            description: @description,
            options: options_payload,
          }
        end
      end

      #
      # Represents the subcommand group.
      #
      class SubcommandGroup < GroupCommand
        # @return [Array<Discorb::ApplicationCommand::Command::SlashCommand>] The subcommands of the command.
        attr_reader :commands

        # @!visibility private
        def initialize(name, description, parent, client)
          super(name, description, [], 1, client)

          @commands = []
          @parent = parent
        end

        def to_s
          @parent + " " + @name
        end

        #
        # Add new subcommand.
        # @param (see Discorb::ApplicationCommand::Handler#slash)
        # @return [Discorb::ApplicationCommand::Command::SlashCommand] The added subcommand.
        #
        def slash(command_name, description, options = {}, &block)
          command = Discorb::ApplicationCommand::Command::SlashCommand.new(command_name, description, options, [], block, 1, @parent + " " + @name)
          @commands << command
          @client.bottom_commands << command
          command
        end
      end

      class << self
        # @!visibility private
        attr_reader :types
      end
    end
  end
end
