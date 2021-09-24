# frozen_string_literal: true

module Discorb
  #
  # Represents a user interaction with the bot.
  #
  class Interaction < DiscordModel
    # @return [Discorb::Snowflake] The ID of the interaction.
    attr_reader :id
    # @return [Discorb::Snowflake] The ID of the application that created the interaction.
    attr_reader :application_id
    # @return [Symbol] The type of interaction.
    attr_reader :type
    # @return [Discorb::Member] The member that created the interaction.
    attr_reader :member
    # @return [Discorb::User] The user that created the interaction.
    attr_reader :user
    # @return [Integer] The type of interaction.
    # @note This is always `1` for now.
    attr_reader :version
    # @return [String] The token for the interaction.
    attr_reader :token

    # @!attribute [r] guild
    #   @macro client_cache
    #   @return [Discorb::Guild] The guild the interaction took place in.
    # @!attribute [r] channel
    #   @macro client_cache
    #   @return [Discorb::Channel] The channel the interaction took place in.
    # @!attribute [r] target
    #   @return [Discorb::User, Discorb::Member] The user or member the interaction took place with.

    @interaction_type = nil
    @interaction_name = nil

    # @!visibility private
    def initialize(client, data)
      @client = client
      @id = Snowflake.new(data[:id])
      @application_id = Snowflake.new(data[:application_id])
      @type = self.class.interaction_name
      @type_id = self.class.interaction_type
      @guild_id = data[:guild_id] && Snowflake.new(data[:guild_id])
      @channel_id = data[:channel_id] && Snowflake.new(data[:channel_id])
      @member = guild.members[data[:member][:id]] || Member.new(@client, @guild_id, data[:member][:user], data[:member]) if data[:member]
      @user = @client.users[data[:user][:id]] || User.new(@client, data[:user]) if data[:user]
      @token = data[:token]
      @version = data[:version]
      @defered = false
      @responded = false
      _set_data(data[:data])
    end

    def guild
      @client.guilds[@guild_id]
    end

    def channel
      @client.channels[@channel_id]
    end

    def target
      @member || @user
    end

    alias fired_by target
    alias from target

    def inspect
      "#<#{self.class} id=#{@id}>"
    end

    class << self
      # @!visibility private
      attr_reader :interaction_type, :interaction_name, :event_name

      # @!visibility private
      def make_interaction(client, data)
        interaction = nil
        descendants.each do |klass|
          interaction = klass.make_interaction(client, data) if !klass.interaction_type.nil? && klass.interaction_type == data[:type]
        end
        if interaction.nil?
          client.log.warn("Unknown interaction type #{data[:type]}, initialized Interaction")
          interaction = Interaction.new(client, data)
        end
        interaction
      end

      # @!visibility private
      def descendants
        ObjectSpace.each_object(Class).select { |klass| klass < self }
      end
    end

    #
    # A module for response with source.
    #
    module SourceResponse
      #
      # Response with `DEFERRED_CHANNEL_MESSAGE_WITH_SOURCE`(`5`).
      #
      # @macro async
      # @macro http
      #
      # @param [Boolean] ephemeral Whether to make the response ephemeral.
      #
      def defer_source(ephemeral: false)
        Async do
          @client.http.post("/interactions/#{@id}/#{@token}/callback", {
            type: 5,
            data: {
              flags: (ephemeral ? 1 << 6 : 0),
            },
          }).wait
          @defered = true
        end
      end

      #
      # Response with `CHANNEL_MESSAGE_WITH_SOURCE`(`4`).
      #
      # @macro async
      # @macro http
      #
      # @param [String] content The content of the response.
      # @param [Boolean] tts Whether to send the message as text-to-speech.
      # @param [Discorb::Embed] embed The embed to send.
      # @param [Array<Discorb::Embed>] embeds The embeds to send. (max: 10)
      # @param [Discorb::AllowedMentions] allowed_mentions The allowed mentions to send.
      # @param [Array<Discorb::Component>, Array<Array<Discorb::Component>>] components The components to send.
      # @param [Boolean] ephemeral Whether to make the response ephemeral.
      #
      # @return [Discorb::Interaction::SourceResponse::CallbackMessage, Discorb::Webhook::Message] The callback message.
      #
      def post(content = nil, tts: false, embed: nil, embeds: nil, allowed_mentions: nil, components: nil, ephemeral: false)
        Async do
          payload = {}
          payload[:content] = content if content
          payload[:tts] = tts
          tmp_embed = if embed
              [embed]
            elsif embeds
              embeds
            end
          payload[:embeds] = tmp_embed.map(&:to_hash) if tmp_embed
          payload[:allowed_mentions] = allowed_mentions ? allowed_mentions.to_hash(@client.allowed_mentions) : @client.allowed_mentions.to_hash
          if components
            tmp_components = []
            tmp_row = []
            components.each do |c|
              case c
              when Array
                tmp_components << tmp_row
                tmp_row = []
                tmp_components << c
              when SelectMenu
                tmp_components << tmp_row
                tmp_row = []
                tmp_components << [c]
              else
                tmp_row << c
              end
            end
            tmp_components << tmp_row
            payload[:components] = tmp_components.filter { |c| c.length.positive? }.map { |c| { type: 1, components: c.map(&:to_hash) } }
          end
          payload[:flags] = (ephemeral ? 1 << 6 : 0)

          ret = if @responded
              _resp, data = @client.http.post("/webhooks/#{@application_id}/#{@token}", payload).wait
              webhook = Webhook::URLWebhook.new("/webhooks/#{@application_id}/#{@token}")
              Webhook::Message.new(webhook, data, @client)
            elsif @defered
              @client.http.patch("/webhooks/#{@application_id}/#{@token}/messages/@original", payload).wait
              CallbackMessage.new(@client, payload, @application_id, @token)
            else
              @client.http.post("/interactions/#{@id}/#{@token}/callback", { type: 4, data: payload }).wait
              CallbackMessage.new(@client, payload, @application_id, @token)
            end
          @responded = true
          ret
        end
      end

      class CallbackMessage
        # @!visibility private
        def initialize(client, data, application_id, token)
          @client = client
          @data = data
          @application_id = application_id
          @token = token
        end

        #
        # Edits the callback message.
        # @macro async
        # @macro http
        # @macro edit
        #
        # @param [Discorb::Webhook::Message] message The message to edit.
        # @param [String] content The new content of the message.
        # @param [Discorb::Embed] embed The new embed of the message.
        # @param [Array<Discorb::Embed>] embeds The new embeds of the message.
        # @param [Array<Discorb::Attachment>] attachments The attachments to remain.
        # @param [Discorb::File] file The file to send.
        # @param [Array<Discorb::File>] files The files to send.
        #
        def edit(
          content = :unset,
          embed: :unset, embeds: :unset,
          file: :unset, files: :unset,
          attachments: :unset
        )
          Async do
            payload = {}
            payload[:content] = content if content != :unset
            payload[:embeds] = embed ? [embed.to_hash] : [] if embed != :unset
            payload[:embeds] = embeds.map(&:to_hash) if embeds != :unset
            payload[:attachments] = attachments.map(&:to_hash) if attachments != :unset
            files = [file] if file != :unset
            if files == :unset
              headers = {
                "Content-Type" => "application/json",
              }
            else
              headers, payload = HTTP.multipart(payload, files)
            end
            @client.http.patch("/webhooks/#{@application_id}/#{@token}/messages/@original", payload, headers: headers).wait
          end
        end

        alias modify edit

        #
        # Deletes the callback message.
        # @note This will fail if the message is ephemeral.
        #
        def delete!
          Async do
            @client.http.delete("/webhooks/#{@application_id}/#{@token}/messages/@original").wait
          end
        end
      end
    end

    #
    # A module for response with update.
    #
    module UpdateResponse
      #
      # Response with `DEFERRED_UPDATE_MESSAGE`(`6`).
      #
      # @param [Boolean] ephemeral Whether to make the response ephemeral.
      #
      def defer_update(ephemeral: false)
        Async do
          @client.http.post("/interactions/#{@id}/#{@token}/callback", {
            type: 7,
            data: {
              flags: (ephemeral ? 1 << 6 : 0),
            },
          }).wait
        end
      end

      #
      # Response with `UPDATE_MESSAGE`(`7`).
      #
      # @macro async
      # @macro http
      #
      # @param [String] content The content of the response.
      # @param [Boolean] tts Whether to send the message as text-to-speech.
      # @param [Discorb::Embed] embed The embed to send.
      # @param [Array<Discorb::Embed>] embeds The embeds to send. (max: 10)
      # @param [Discorb::AllowedMentions] allowed_mentions The allowed mentions to send.
      # @param [Array<Discorb::Component>, Array<Array<Discorb::Component>>] components The components to send.
      # @param [Boolean] ephemeral Whether to make the response ephemeral.
      #
      def edit(content, tts: false, embed: nil, embeds: nil, allowed_mentions: nil, components: nil, ephemeral: false)
        Async do
          payload = {}
          payload[:content] = content if content
          payload[:tts] = tts
          tmp_embed = if embed
              [embed]
            elsif embeds
              embeds
            end
          payload[:embeds] = tmp_embed.map(&:to_hash) if tmp_embed
          payload[:allowed_mentions] = allowed_mentions ? allowed_mentions.to_hash(@client.allowed_mentions) : @client.allowed_mentions.to_hash
          if components
            tmp_components = []
            tmp_row = []
            components.each do |c|
              case c
              when Array
                tmp_components << tmp_row
                tmp_row = []
                tmp_components << c
              when SelectMenu
                tmp_components << tmp_row
                tmp_row = []
                tmp_components << [c]
              else
                tmp_row << c
              end
            end
            tmp_components << tmp_row
            payload[:components] = tmp_components.filter { |c| c.length.positive? }.map { |c| { type: 1, components: c.map(&:to_hash) } }
          end
          payload[:flags] = (ephemeral ? 1 << 6 : 0)
          @client.http.post("/interactions/#{@id}/#{@token}/callback", { type: 6, data: payload }).wait
        end
      end
    end

    private

    def _set_data(*)
      nil
    end
  end

  #
  # Represents a command interaction.
  #
  class CommandInteraction < Interaction
    @interaction_type = 2
    @interaction_name = :application_command
    include Interaction::SourceResponse

    #
    # Represents a slash command interaction.
    #
    class SlashCommand < CommandInteraction
      @command_type = 1

      private

      def _set_data(data)
        super
        Sync do
          name = data[:name]
          options = nil
          if (option = data[:options]&.first)
            case option[:type]
            when 1
              name += " #{option[:name]}"
              options = option[:options]
            when 2
              name += " #{option[:name]}"
              if (option_sub = option[:options]&.first)
                if option_sub[:type] == 1
                  name += " #{option_sub[:name]}"
                  options = option_sub[:options]
                else
                  options = option[:options]
                end
              end
            else
              options = data[:options]
            end
          end
          options ||= []
          options.map! do |option|
            case option[:type]
            when 3, 4, 5, 10
              option[:value]
            when 6
              guild.members[option[:value]] || guild.fetch_member(option[:value]).wait
            when 7
              guild.channels[option[:value]] || guild.fetch_channels.wait.find { |channel| channel.id == option[:value] }
            when 8
              guild.roles[option[:value]] || guild.fetch_roles.wait.find { |role| role.id == option[:value] }
            when 9
              guild.members[option[:value]] || guild.roles[option[:value]] || guild.fetch_member(option[:value]).wait || guild.fetch_roles.wait.find { |role| role.id == option[:value] }
            end
          end

          unless (command = @client.bottom_commands.find { |c| c.to_s == name && c.type_raw == 1 })
            @client.log.warn "Unknown command name #{name}, ignoreing"
            next
          end

          command.block.call(self, *options)
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
        @target = Message.new(@client, data[:resolved][:messages][data[:target_id].to_sym])
        @client.commands.find { |c| c.name == data[:name] && c.type_raw == 3 }.block.call(self, @target)
      end
    end

    private

    def _set_data(data)
      @name = data[:name]
    end

    class << self
      # @!visibility private
      attr_reader :command_type

      # @!visibility private
      def make_interaction(client, data)
        nested_classes.each do |klass|
          return klass.new(client, data) if !klass.command_type.nil? && klass.command_type == data[:data][:type]
        end
        client.log.warn("Unknown command type #{data[:type]}, initialized CommandInteraction")
        CommandInteraction.new(client, data)
      end

      # @!visibility private
      def nested_classes
        constants.select { |c| const_get(c).is_a? Class }.map { |c| const_get(c) }
      end
    end
  end

  #
  # Represents a message component interaction.
  # @abstract
  #
  class MessageComponentInteraction < Interaction
    include Interaction::SourceResponse
    include Interaction::UpdateResponse
    # @return [String] The content of the response.
    attr_reader :custom_id

    @interaction_type = 3
    @interaction_name = :message_component

    # @!visibility private
    def initialize(client, data)
      super
      @message = Message.new(@client, data[:message].merge({ member: data[:member] }))
    end

    class << self
      # @!visibility private
      attr_reader :component_type

      # @!visibility private
      def make_interaction(client, data)
        nested_classes.each do |klass|
          return klass.new(client, data) if !klass.component_type.nil? && klass.component_type == data[:data][:component_type]
        end
        client.log.warn("Unknown component type #{data[:component_type]}, initialized Interaction")
        MessageComponentInteraction.new(client, data)
      end

      # @!visibility private
      def nested_classes
        constants.select { |c| const_get(c).is_a? Class }.map { |c| const_get(c) }
      end
    end

    #
    # Represents a button interaction.
    #
    class Button < MessageComponentInteraction
      @component_type = 2
      @event_name = :button_click
      # @return [String] The custom id of the button.
      attr_reader :custom_id

      private

      def _set_data(data)
        @custom_id = data[:custom_id]
      end
    end

    #
    # Represents a select menu interaction.
    #
    class SelectMenu < MessageComponentInteraction
      @component_type = 3
      @event_name = :select_menu_select
      # @return [String] The custom id of the select menu.
      attr_reader :custom_id
      # @return [Array<String>] The selected options.
      attr_reader :values

      # @!attribute [r] value
      #   @return [String] The first selected value.

      def value
        @values[0]
      end

      private

      def _set_data(data)
        @custom_id = data[:custom_id]
        @values = data[:values]
      end
    end
  end
end
