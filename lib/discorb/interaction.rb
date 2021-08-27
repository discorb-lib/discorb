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

    def inspect
      "#<#{self.class} id=#{@id}>"
    end

    class << self
      # @!visibility private
      attr_reader :interaction_type, :interaction_name, :event_name

      # @!visibility private
      def make_interaction(client, data)
        descendants.each do |klass|
          return klass.make_interaction(client, data) if !klass.interaction_type.nil? && klass.interaction_type == data[:type]
        end
        client.log.warn("Unknown interaction type #{data[:type]}, initialized Interaction")
        Interaction.new(client, data)
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
      # @param [Boolean] hide Whether to hide the response (ephemeral).
      #
      def defer_source(hide: false)
        Async do
          @client.internet.post("/interactions/#{@id}/#{@token}/callback", {
            type: 5,
            data: {
              flags: (hide ? 1 << 6 : 0),
            },
          }).wait
          @defered = true
        end
      end

      #
      # Response with `CHANNEL_MESSAGE_WITH_SOURCE`(`4`).
      #
      # @param [String] content The content of the response.
      # @param [Boolean] tts Whether to send the message as text-to-speech.
      # @param [Discorb::Embed] embed The embed to send.
      # @param [Array<Discorb::Embed>] embeds The embeds to send. (max: 10)
      # @param [Discorb::AllowedMentions] allowed_mentions The allowed mentions to send.
      # @param [Array<Discorb::Components>, Array<Array<Discorb::Components>>] components The components to send.
      # @param [Boolean] hide Whether to hide the response (ephemeral).
      #
      def post(content, tts: false, embed: nil, embeds: nil, allowed_mentions: nil, components: nil, hide: false)
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
        payload[:flags] = (hide ? 1 << 6 : 0)
        if @responded
          @client.internet.post("/webhooks/#{@id}/#{@token}", { type: 4, data: payload }).wait
        elsif @defered
          @client.internet.post("/interactions/#{@id}/#{@token}/@original/edit", { type: 4, data: payload }).wait
        else
          @client.internet.post("/interactions/#{@id}/#{@token}/callback", { type: 4, data: payload }).wait
        end
        @responded = true
      end
    end

    #
    # A module for response with update.
    #
    module UpdateResponse
      #
      # Response with `DEFERRED_UPDATE_MESSAGE`(`6`).
      #
      # @param [Boolean] hide Whether to hide the response (ephemeral).
      #
      def defer_update(hide: false)
        Async do
          @client.internet.post("/interactions/#{@id}/#{@token}/callback", {
            type: 7,
            data: {
              flags: (hide ? 1 << 6 : 0),
            },
          }).wait
        end
      end

      #
      # Response with `UPDATE_MESSAGE`(`7`).
      #
      # @param [String] content The content of the response.
      # @param [Boolean] tts Whether to send the message as text-to-speech.
      # @param [Discorb::Embed] embed The embed to send.
      # @param [Array<Discorb::Embed>] embeds The embeds to send. (max: 10)
      # @param [Discorb::AllowedMentions] allowed_mentions The allowed mentions to send.
      # @param [Array<Discorb::Components>, Array<Array<Discorb::Components>>] components The components to send.
      # @param [Boolean] hide Whether to hide the response (ephemeral).
      #
      def edit(content, tts: false, embed: nil, embeds: nil, allowed_mentions: nil, components: nil, hide: false)
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
        payload[:flags] = (hide ? 1 << 6 : 0)
        @client.internet.post("/interactions/#{@id}/#{@token}/callback", { type: 6, data: payload }).wait
      end
    end

    private

    def _set_data(*)
      nil
    end
  end

  #
  # Represents a slash command interaction.
  # @todo Implement this.
  #
  class SlashCommandInteraction < Interaction
    @interaction_type = 2
    @interaction_name = :slash_command

    def _set_data(data)
      p data
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
          return klass.new(client, data) if !klass.component_type.nil? && klass.component_type == data[:type]
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
