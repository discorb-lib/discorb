# frozen_string_literal: true

module Discorb
  #
  # Handles application commands.
  #
  module ApplicationCommand
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

      # @private
      # @return [{Integer => Symbol}] The mapping of raw types to types.
      TYPES = {
        1 => :chat_input,
        2 => :user,
        3 => :message,
      }.freeze

      #
      # Initialize a new command.
      # @private
      #
      # @param [String] name The name of the command.
      # @param [Array<#to_s>] guild_ids The guild ids that the command is enabled in.
      # @param [Proc] block The block of the command.
      # @param [:chat_input, :user, :message] type The type of the command.
      #
      def initialize(name, guild_ids, block, type)
        @name = name
        @guild_ids = guild_ids&.map(&:to_s)
        @block = block
        @raw_type = type
        @type = Discorb::ApplicationCommand::Command::TYPES[type]
        @type_raw = type
        @id_map = Discorb::Dictionary.new
      end

      #
      # Changes the self pointer to the given object.
      # @private
      #
      # @param [Object] instance The object to change the self pointer to.
      #
      def replace_block(instance)
        current_block = @block.dup
        @block = proc do |*args|
          instance.instance_exec(*args, &current_block)
        end
      end

      #
      # Converts the object to a hash.
      # @private
      #
      # @return [Hash] The hash represents the object.
      #
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

        #
        # Initialize a new slash command.
        # @private
        #
        # @param [String] name The name of the command.
        # @param [String] description The description of the command.
        # @param [Hash{String => Hash}] options The options of the command.
        # @param [Array<#to_s>] guild_ids The guild ids that the command is enabled in.
        # @param [Proc] block The block of the command.
        # @param [:chat_input, :user, :message] type The type of the command.
        # @param [Discorb::ApplicationCommand::Command, nil] parent The parent command.
        #
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

        #
        # Converts the object to a hash.
        # @private
        #
        # @return [Hash] The hash represents the object.
        #
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
              when :attachment
                11
              else
                raise ArgumentError, "Invalid option type: #{value[:type]}"
              end,
              name: name,
              description: value[:description],
              required: value[:required].nil? ? !value[:optional] : value[:required],
            }

            ret[:choices] = value[:choices].map { |t| { name: t[0], value: t[1] } } if value[:choices]

            ret[:channel_types] = value[:channel_types].map(&:channel_type) if value[:channel_types]

            ret[:autocomplete] = !value[:autocomplete].nil? if value[:autocomplete]
            if value[:range]
              ret[:min_value] = value[:range].begin
              ret[:max_value] = value[:range].end
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

        #
        # Initialize a new group command.
        # @private
        #
        # @param [String] name The name of the command.
        # @param [String] description The description of the command.
        # @param [Array<#to_s>] guild_ids The guild ids that the command is enabled in.
        # @param [:chat_input, :user, :message] type The type of the command.
        # @param [Discorb::Client] client The client of the command.
        #
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
        # @see file:docs/application_command.md Application Commands
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

        #
        # Changes the self pointer to the given object.
        # @private
        #
        # @param [Object] instance The object to change to.
        #
        def block_replace(instance)
          super
          @commands.each { |c| c.replace_block(instance) }
        end

        #
        # Converts the object to a hash.
        # @private
        #
        # @return [Hash] The hash represents the object.
        #
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

        #
        # Initialize a new subcommand group.
        # @private
        #
        # @param [String] name The name of the command.
        # @param [String] description The description of the command.
        # @param [Discorb::ApplicationCommand::Command::GroupCommand] parent The parent command.
        # @param [Discorb::Client] client The client.
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
    end
  end
end
