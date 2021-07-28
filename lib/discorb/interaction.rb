# frozen_string_literal: true

require_relative 'common'

module Discorb
  class Interaction < DiscordModel
    attr_reader :id, :application_id, :type, :member, :user, :version, :token

    @interaction_type = nil
    @interaction_name = nil
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
      _set_data(data[:data])
    end

    def guild
      @client.guilds[@guild_id]
    end

    def channel
      @client.channels[@channel_id]
    end

    def fired_by
      @member || @user
    end

    def inspect
      "#<#{self.class} id=#{@id}>"
    end

    class << self
      attr_reader :interaction_type, :interaction_name, :event_name

      def make_interaction(client, data)
        descendants.each do |klass|
          return klass.make_interaction(client, data) if !klass.interaction_type.nil? && klass.interaction_type == data[:type]
        end
        client.log.warn("Unknown interaction type #{data[:type]}, initialized Interaction")
        Interaction.new(client, data)
      end

      def descendants
        ObjectSpace.each_object(Class).select { |klass| klass < self }
      end
    end

    module SourceResponse
      def defer_source(hide: false)
        Async do
          @client.internet.post("/interactions/#{@id}/#{@token}/callback",
                                {
                                  type: 5,
                                  data: {
                                    flags: (hide ? 1 << 6 : 0)
                                  }
                                }).wait
        end
      end

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
        @client.internet.post("/interactions/#{@id}/#{@token}/callback", { type: 4, data: payload }).wait
      end
    end

    module UpdateResponse
      def defer_update(hide: false)
        Async do
          @client.internet.post("/interactions/#{@id}/#{@token}/callback",
                                {
                                  type: 7,
                                  data: {
                                    flags: (hide ? 1 << 6 : 0)
                                  }
                                }).wait
        end
      end

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
        @client.internet.post("/interactions/#{@id}/#{@token}/callback", { type: 6, data: payload }).wait
      end
    end

    private

    def _set_data(*)
      nil
    end
  end

  class SlashCommandInteraction < Interaction
    @interaction_type = 2
    @interaction_name = :slash_command

    def _set_data(data)
      p data
    end
  end

  class MessageComponentInteraction < Interaction
    include Interaction::SourceResponse
    attr_reader :component_type, :custom_id, :values

    @interaction_type = 3
    @interaction_name = :message_component

    def initialize(client, data)
      super
      @message = Message.new(@client, data[:message].merge({ member: data[:member] }))
    end

    class << self
      attr_reader :component_type

      def make_interaction(client, data)
        nested_classes.each do |klass|
          return klass.new(client, data) if !klass.component_type.nil? && klass.component_type == data[:type]
        end
        client.log.warn("Unknown component type #{data[:component_type]}, initialized Interaction")
        MessageComponentInteraction.new(client, data)
      end

      def nested_classes
        constants.select { |c| const_get(c).is_a? Class }.map { |c| const_get(c) }
      end
    end

    class Button < MessageComponentInteraction
      @component_type = 2
      @event_name = :button_click
      attr_reader :custom_id

      private

      def _set_data(data)
        @custom_id = data[:custom_id]
      end
    end

    class SelectMenu < MessageComponentInteraction
      @component_type = 3
      @event_name = :select_menu_select
      attr_reader :custom_id, :values

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
