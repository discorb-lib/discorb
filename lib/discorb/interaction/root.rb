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
    # @return [Symbol] The locale of the user that created the interaction.
    # @note This modifies the language code, `-` will be replaced with `_`.
    attr_reader :locale
    # @return [Symbol] The locale of the guild that created the interaction.
    # @note This modifies the language code, `-` will be replaced with `_`.
    attr_reader :guild_locale

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

    # @private
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
      @locale = data[:locale].to_s.gsub("-", "_").to_sym
      @guild_locale = data[:guild_locale].to_s.gsub("-", "_").to_sym
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
      # @private
      attr_reader :interaction_type, :interaction_name, :event_name

      # @private
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

      # @private
      def descendants
        ObjectSpace.each_object(Class).select { |klass| klass < self }
      end
    end
  end
end
