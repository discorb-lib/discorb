# frozen_string_literal: true

module Discorb
  module ApplicationCommand
    #
    # Represents a application command.
    # @abstract
    #
    class Command < DiscordModel
      # @return [Hash{String => String}] The name of the command.
      attr_reader :name
      # @return [Array<#to_s>] The guild ids that the command is enabled in.
      attr_reader :guild_ids
      # @return [Proc] The block of the command.
      attr_reader :block
      # @return [:chat_input, :user, :message] The type of the command.
      attr_reader :type
      # @return [Integer] The raw type of the command.
      attr_reader :type_raw
      # @return [Discorb::Permission] The default permissions for this command.
      attr_reader :default_permission
      # @return [Boolean] Whether the command is enabled in DMs.
      attr_reader :dm_permission

      # @private
      # @return [{Integer => Symbol}] The mapping of raw types to types.
      TYPES = { 1 => :chat_input, 2 => :user, 3 => :message }.freeze

      #
      # Initialize a new command.
      # @private
      #
      # @param [String, Hash{Symbol => String}] name The name of the command.
      # @param [Array<#to_s>, false, nil] guild_ids The guild ids that the command is enabled in.
      # @param [Proc] block The block of the command.
      # @param [Integer] type The type of the command.
      # @param [Boolean] dm_permission Whether the command is enabled in DMs.
      # @param [Discorb::Permission] default_permission The default permission of the command.
      #
      def initialize(
        name,
        guild_ids,
        block,
        type,
        dm_permission = true,
        default_permission = nil
      )
        @name =
          (
            if name.is_a?(String)
              { "default" => name }
            else
              ApplicationCommand.modify_localization_hash(name)
            end
          )
        @guild_ids = guild_ids&.map(&:to_s)
        @block = block
        @type = Discorb::ApplicationCommand::Command::TYPES[type]
        @type_raw = type
        @dm_permission = dm_permission
        @default_permission = default_permission
      end

      #
      # Changes the self pointer of block to the given object.
      # @private
      #
      # @param [Object] instance The object to change the self pointer to.
      #
      def replace_block(instance)
        current_block = @block.dup
        @block = proc { |*args| instance.instance_exec(*args, &current_block) }
      end

      #
      # Converts the object to a hash.
      # @private
      #
      # @return [Hash] The hash represents the object.
      #
      def to_hash
        {
          name: @name["default"],
          name_localizations: @name.except("default"),
          type: @type_raw,
          dm_permission: @dm_permission,
          default_member_permissions: @default_permission&.value&.to_s
        }
      end

      #
      # Represents the slash command.
      #
      class ChatInputCommand < Command
        # @return [Hash{String => String}] The description of the command.
        attr_reader :description
        # @return [Hash{String => Hash}] The options of the command.
        attr_reader :options

        #
        # Initialize a new slash command.
        # @private
        #
        # @param [String, Hash{Symbol => String}] name The name of the command.
        #   The hash should have `default`, and language keys.
        # @param [String, Hash{Symbol => String}] description The description of the command.
        #   The hash should have `default`, and language keys.
        # @param [Hash{String => Hash}] options The options of the command.
        # @param [Array<#to_s>] guild_ids The guild ids that the command is enabled in.
        # @param [Proc] block The block of the command.
        # @param [Integer] type The type of the command.
        # @param [Discorb::ApplicationCommand::Command, nil] parent The parent command.
        # @param [Boolean] dm_permission Whether the command is enabled in DMs.
        # @param [Discorb::Permission] default_permission The default permission of the command.
        #
        def initialize(
          name,
          description,
          options,
          guild_ids,
          block,
          type,
          parent,
          dm_permission,
          default_permission
        )
          super(name, guild_ids, block, type, dm_permission, default_permission)
          @description =
            if description.is_a?(String)
              { "default" => description }
            else
              ApplicationCommand.modify_localization_hash(description)
            end
          @options = options
          @parent = parent
        end

        #
        # Returns the commands name.
        #
        # @return [String] The name of the command.
        #
        def to_s
          "#{@parent} #{@name["default"]}".strip
        end

        #
        # Converts the object to a hash.
        # @private
        #
        # @return [Hash] The hash represents the object.
        #
        def to_hash
          options_payload =
            options.map do |name, value|
              ret = {
                type:
                  case value[:type]
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
                name:,
                name_localizations:
                  ApplicationCommand.modify_localization_hash(
                    value[:name_localizations]
                  ),
                required:
                  value[:required].nil? ? !value[:optional] : value[:required]
              }

              if value[:description].is_a?(String)
                ret[:description] = value[:description]
              else
                description =
                  ApplicationCommand.modify_localization_hash(
                    value[:description]
                  )
                ret[:description] = description["default"]
                ret[:description_localizations] = description.except("default")
              end
              if value[:choices]
                ret[:choices] = value[:choices].map do |k, v|
                  r = { name: k, value: v }
                  if choices_localizations = value[:choices_localizations].clone
                    name_localizations =
                      ApplicationCommand.modify_localization_hash(
                        choices_localizations.delete(k) do
                          warn "Missing localization for #{k}"
                          {}
                        end
                      )
                    r[:name_localizations] = name_localizations.except(
                      "default"
                    )
                    r[:name] = name_localizations["default"]
                    r.delete(:name_localizations) if r[:name_localizations].nil?
                  end
                  r
                end
              end

              ret[:channel_types] = value[:channel_types].map(
                &:channel_type
              ) if value[:channel_types]

              ret[:autocomplete] = !value[:autocomplete].nil? if value[
                :autocomplete
              ]
              if value[:range]
                ret[:min_value] = value[:range].begin
                ret[:max_value] = value[:range].end
              end
              if value[:length]
                ret[:min_length] = value[:length].begin
                ret[:max_length] = value[:length].end
              end
              ret
            end
          {
            name: @name["default"],
            name_localizations: @name.except("default"),
            description: @description["default"],
            description_localizations: @description.except("default"),
            options: options_payload,
            dm_permission: @dm_permission,
            default_member_permissions: @default_permission&.value&.to_s
          }
        end
      end

      #
      # Represents the command with subcommands.
      #
      class GroupCommand < Command
        # @return [Array<Discorb::ApplicationCommand::Command>] The subcommands of the command.
        attr_reader :commands
        # @return [Hash{String => String}] The description of the command.
        attr_reader :description

        #
        # Initialize a new group command.
        # @private
        #
        # @param [String, Hash{Symbol => String}] name The name of the command.
        # @param [String, Hash{Symbol => String}] description The description of the command.
        # @param [Array<#to_s>] guild_ids The guild ids that the command is enabled in.
        # @param [Discorb::Client] client The client of the command.
        # @param [Boolean] dm_permission Whether the command is enabled in DMs.
        # @param [Discorb::Permission] default_permission The default permission of the command.
        #
        def initialize(
          name,
          description,
          guild_ids,
          client,
          dm_permission,
          default_permission
        )
          super(name, guild_ids, block, 1, dm_permission, default_permission)
          @description =
            if description.is_a?(String)
              { "default" => description }
            else
              ApplicationCommand.modify_localization_hash(description)
            end
          @commands = []
          @client = client
        end

        #
        # Add new subcommand.
        #
        # @param (see Discorb::ApplicationCommand::Handler#slash)
        # @return [Discorb::ApplicationCommand::Command::ChatInputCommand] The added subcommand.
        #
        def slash(
          command_name,
          description,
          options = {},
          dm_permission: true,
          default_permission: nil,
          &block
        )
          command =
            Discorb::ApplicationCommand::Command::ChatInputCommand.new(
              command_name,
              description,
              options,
              [],
              block,
              1,
              self,
              dm_permission,
              default_permission
            )
          @client.callable_commands << command
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
        def group(command_name, description)
          command =
            Discorb::ApplicationCommand::Command::SubcommandGroup.new(
              command_name,
              description,
              self,
              @client
            )
          yield command if block_given?
          @commands << command
          command
        end

        #
        # Returns the command name.
        #
        # @return [String] The command name.
        #
        def to_s
          @name["default"]
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
          options_payload =
            @commands.map do |command|
              if command.is_a?(ChatInputCommand)
                {
                  name: command.name["default"],
                  name_localizations: command.name.except("default"),
                  description: command.description["default"],
                  description_localizations:
                    command.description.except("default"),
                  type: 1,
                  options: command.to_hash[:options]
                }
              else
                {
                  name: command.name["default"],
                  name_localizations: command.name.except("default"),
                  description: command.description["default"],
                  description_localizations:
                    command.description.except("default"),
                  type: 2,
                  options:
                    command.commands.map do |c|
                      c
                        .to_hash
                        .merge(type: 1)
                        .except(:dm_permission, :default_member_permissions)
                    end
                }
              end
            end

          {
            name: @name["default"],
            name_localizations: @name.except("default"),
            description: @description["default"],
            description_localizations: @description.except("default"),
            dm_permission: @dm_permission,
            default_member_permissions: @default_permission&.value&.to_s,
            options: options_payload
          }
        end
      end

      #
      # Represents the subcommand group.
      #
      class SubcommandGroup < GroupCommand
        # @return [Array<Discorb::ApplicationCommand::Command::ChatInputCommand>] The subcommands of the command.
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
          super(name, description, [], client, nil, nil)

          @commands = []
          @parent = parent
        end

        def to_s
          "#{@parent} #{@name}"
        end

        #
        # Add new subcommand.
        # @param (see Discorb::ApplicationCommand::Handler#slash)
        # @return [Discorb::ApplicationCommand::Command::ChatInputCommand] The added subcommand.
        #
        def slash(command_name, description, options = {}, &block)
          command =
            Discorb::ApplicationCommand::Command::ChatInputCommand.new(
              command_name,
              description,
              options,
              [],
              block,
              1,
              self,
              nil,
              nil
            )
          @commands << command
          @client.callable_commands << command
          command
        end
      end
    end
  end
end
