# frozen_string_literal: true

module Discorb
  #
  # Handles application commands.
  #
  module Command
    #
    # Module to handle commands.
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
      # @param [Array<#to_s>] guild_ids Guild IDs to restrict the command to.
      # @param [Proc] block Command block.
      #
      # @return [Discorb::Command::Command::SlashCommand]
      #
      # @see file:docs/application_command.md#register-slash-command
      #
      def slash(command_name, description, options = {}, guild_ids: [], &block)
        command = Discorb::Command::Command::SlashCommand.new(command_name, description, options, guild_ids, block, 1, "")
        @commands << command
        command
      end

      #
      # Add new command with group.
      #
      # @param [String] command_name Command name.
      # @param [String] description Command description.
      # @param [Array<#to_s>] guild_ids Guild IDs to restrict the command to.
      #
      # @return [Discorb::Command::Command::GroupCommand] Command object.
      #
      # @see file:docs/slash_command.md
      #
      def slash_group(command_name, description, guild_ids: [])
        command = Discorb::Command::Command::GroupCommand.new(command_name, description, guild_ids, nil)
        @commands << command
        command
      end

      #
      # Add message context menu command.
      #
      # @param [String] command_name Command name.
      # @param [Array<#to_s>] guild_ids Guild IDs to restrict the command to.
      # @param [Proc] block Command block.
      #
      # @return [Discorb::Command::Command] Command object.
      #
      def message_menu(command_name, guild_ids: [], &block)
        command = Discorb::Command::Command.new(command_name, guild_ids, block, 3)
        @commands << command
        command
      end

      #
      # Add user context menu command.
      #
      # @param [String] command_name Command name.
      # @param [Array<#to_s>] guild_ids Guild IDs to restrict the command to.
      # @param [Proc] block Command block.
      #
      # @return [Discorb::Command::Command] Command object.
      #
      def user_menu(command_name, guild_ids: [], &block)
        command = Discorb::Command::Command.new(command_name, guild_ids, block, 2)
        @commands << command
        command
      end

      #
      # Setup commands.
      # @note This method is called automatically if overwrite_application_commands is set to true.
      #   @see Client#initialize
      #
      # @param [String] token Bot token.
      #   @note This only required if you don't run client.
      #
      def setup_commands(token = nil)
        Async do
          @token ||= token
          @http = HTTP.new(self)
          global_commands = @commands.select { |c| c.guild_ids.empty? }
          guild_ids = Set[*@commands.map(&:guild_ids).flatten]
          app_info = fetch_application.wait
          http.put("/applications/#{app_info.id}/commands", global_commands.map(&:to_hash)).wait unless global_commands.empty?
          guild_ids.each do |guild_id|
            commands = @commands.select { |c| c.guild_ids.include?(guild_id) }
            http.put("/applications/#{app_info.id}/guilds/#{guild_id}/commands", commands.map(&:to_hash)).wait
          end unless guild_ids.empty?
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
        @guild_ids = guild_ids.map(&:to_s)
        @block = block
        @raw_type = type
        @type = Discorb::Command::Command.types[type]
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
          @description = description
          @name = name
          @guild_ids = guild_ids.map(&:to_s)
          @block = block
          @type = Discorb::Command::Command.types[type]
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
        # @return [Array<Discorb::Command::Command::SlashCommand, Discorb::Command::Command::SubcommandGroup>] The subcommands of the command.
        attr_reader :commands
        # @return [String] The description of the command.
        attr_reader :description

        # @!visibility private
        def initialize(name, description, guild_ids, type)
          super(name, guild_ids, block, type)
          @description = description
          @commands = []
          @id_map = Discorb::Dictionary.new
        end

        #
        # Add new subcommand.
        #
        # @param (see Discorb::Command::Handler#slash)
        # @return [Discorb::Command::Command::SlashCommand] The added subcommand.
        #
        def slash(command_name, description, options = {}, &block)
          command = Discorb::Command::Command::SlashCommand.new(command_name, description, options, [], block, 1, @name)
          options_payload = options.map do |name, value|
            ret = {
              type: case (value[:type].is_a?(Array) ? value[:type].first : value[:type])
              when String, :string
                3
              when Integer
                4
              when TrueClass, FalseClass, :boolean
                5
              when Discorb::User, Discorb::Member, :user, :member
                6
              when Discorb::Channel, :channel
                7
              when Discorb::Role, :role
                8
              when :mentionable
                9
              when Float
                10
              end,
              name: name,
              description: value[:description],
              required: !value[:optional],
            }
            if value[:type].is_a?(Array)
              ret[:choices] = value[:type]
            end

            ret
          end
          {
            name: @name,
            default_permission: true,
            description: @description,
            options: options_payload,
          }
          @commands << command
          command
        end

        #
        # Add new subcommand group.
        #
        # @param [String] command_name Group name.
        # @param [String] description Group description.
        #
        # @return [Discorb::Command::Command::SubcommandGroup] Command object.
        #
        # @see file:docs/slash_command.md
        #
        def group(command_name, description)
          command = Discorb::Command::Command::SubcommandGroup.new(command_name, description, @name)
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
                default_permission: command.enabled,
                type: 1,
                options: command.to_hash[:options],
              }
            else
              {
                name: command.name,
                description: command.description,
                default_permission: command.enabled,
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
        # @return [Array<Discorb::Command::Command::SlashCommand>] The subcommands of the command.
        attr_reader :commands

        # @!visibility private
        def initialize(name, description, enabled, parent)
          super(name, description, [], enabled, 1)

          @commands = []
          @parent = parent
        end

        def to_s
          @parent + " " + @name
        end

        #
        # Add new subcommand.
        # @param (see Discorb::Command::Handler#slash)
        # @return [Discorb::Command::Command::SlashCommand] The added subcommand.
        #
        def slash(command_name, description, options = {}, enabled: true, &block)
          command = Discorb::Command::Command::SlashCommand.new(command_name, description, options, [], enabled, block, 1, @parent + " " + @name)
          @commands << command
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
