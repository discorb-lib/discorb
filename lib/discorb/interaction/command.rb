module Discorb
  #
  # Represents a command interaction.
  #
  class CommandInteraction < Interaction
    @interaction_type = 2
    @interaction_name = :application_command
    include Interaction::SourceResponse
    include Interaction::ModalResponse

    #
    # Represents a slash command interaction.
    #
    class SlashCommand < CommandInteraction
      @command_type = 1

      private

      def _set_data(data)
        super

        name, options = SlashCommand.get_command_data(data)

        unless (command = @client.bottom_commands.find { |c| c.to_s == name && c.type_raw == 1 })
          @client.log.warn "Unknown command name #{name}, ignoring"
          return
        end

        option_map = command.options.map { |k, v| [k.to_s, v[:default]] }.to_h
        SlashCommand.modify_option_map(option_map, options, guild, @members, @attachments)

        command.block.call(self, *command.options.map { |k, v| option_map[k.to_s] })
      end

      class << self
        # @private
        def get_command_data(data)
          name = data[:name]
          options = nil
          return name, options unless (option = data[:options]&.first)

          case option[:type]
          when 1
            name += " #{option[:name]}"
            options = option[:options]
          when 2
            name += " #{option[:name]}"
            unless option[:options]&.first&.[](:type) == 1
              options = option[:options]
              return name, options
            end
            option_sub = option[:options]&.first
            name += " #{option_sub[:name]}"
            options = option_sub[:options]
          else
            options = data[:options]
          end

          return name, options
        end

        # @private
        def modify_option_map(option_map, options, guild, members, attachments)
          options ||= []
          options.each_with_index do |option|
            val = case option[:type]
              when 3, 4, 5, 10
                option[:value]
              when 6
                guild.members[option[:value]] || guild.fetch_member(option[:value]).wait
              when 7
                guild.channels[option[:value]] || guild.fetch_channels.wait.find { |channel| channel.id == option[:value] }
              when 8
                guild.roles[option[:value]] || guild.fetch_roles.wait.find { |role| role.id == option[:value] }
              when 9
                members[option[:value]] || guild.members[option[:value]] || guild.roles[option[:value]] || guild.fetch_member(option[:value]).wait || guild.fetch_roles.wait.find { |role| role.id == option[:value] }
              when 11
                attachments[option[:value]]
              end
            option_map[option[:name]] = val
          end
        end
      end
    end

    #
    # Represents a user context menu interaction.
    #
    class UserMenuCommand < CommandInteraction
      @command_type = 2

      # @return [Discorb::Member, Discorb::User] The target user.
      attr_reader :target

      private

      def _set_data(data)
        super
        @target = guild.members[data[:target_id]] || Discorb::Member.new(@client, @guild_id, data[:resolved][:users][data[:target_id].to_sym], data[:resolved][:members][data[:target_id].to_sym])
        @client.commands.find { |c| c.name == data[:name] && c.type_raw == 2 }.block.call(self, @target)
      end
    end

    #
    # Represents a message context menu interaction.
    #
    class MessageMenuCommand < CommandInteraction
      @command_type = 3

      # @return [Discorb::Message] The target message.
      attr_reader :target

      private

      def _set_data(data)
        super
        @target = @messages[data[:target_id]]
        @client.commands.find { |c| c.name == data[:name] && c.type_raw == 3 }.block.call(self, @target)
      end
    end

    private

    def _set_data(data)
      super
      @name = data[:name]
      @messages, @attachments, @members = {}, {}, {}

      if data[:resolved]
        data[:resolved][:users]&.each do |id, user|
          @client.users[id] = Discorb::User.new(@client, user)
        end
        data[:resolved][:members]&.each do |id, member|
          @members[id] = Discorb::Member.new(
            @client, @guild_id, data[:resolved][:users][id], member
          )
        end
        data[:resolved][:messages]&.to_h do |id, message|
          @messages[id.to_i] = Message.new(@client, data[:resolved][:messages][data[:target_id].to_sym].merge(guild_id: @guild_id.to_s)).merge(guild_id: @guild_id.to_s)
        end
        data[:resolved][:attachments]&.to_h do |id, attachment|
          @attachments[id.to_s] = Attachment.new(attachment)
        end
      end
    end

    class << self
      # @private
      attr_reader :command_type

      # @private
      def make_interaction(client, data)
        nested_classes.each do |klass|
          return klass.new(client, data) if !klass.command_type.nil? && klass.command_type == data[:data][:type]
        end
        client.log.warn("Unknown command type #{data[:type]}, initialized CommandInteraction")
        CommandInteraction.new(client, data)
      end

      # @private
      def nested_classes
        constants.select { |c| const_get(c).is_a? Class }.map { |c| const_get(c) }
      end
    end
  end
end
