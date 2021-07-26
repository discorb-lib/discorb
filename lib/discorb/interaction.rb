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
      @message = Message.new(@client, data[:message].merge({ member: data[:member] })) if data[:message]
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

    class << self
      attr_reader :interaction_type, :interaction_name

      def make_interaction(client, data)
        descendants.each do |klass|
          return klass.new(client, data) if !klass.interaction_type.nil? && klass.interaction_type == data[:type]
        end
        client.log.warn("Unknown interaction_type type #{data[:type]}, initialized Interaction")
        Interaction.new(client, data)
      end

      def descendants
        ObjectSpace.each_object(Class).select { |klass| klass < self }
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
    @interaction_type = 3
    @interaction_name = :message_component

    def _set_data(data)
      @custom_id = data[:custom_id].to_sym
      @component_type = data[:component_type]
    end
  end
end
