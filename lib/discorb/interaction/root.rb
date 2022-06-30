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
    # @return [Discorb::User, Discorb::Member] The user or member that created the interaction.
    attr_reader :user
    alias member user
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
    # @return [Discorb::Permission] The permissions of the bot.
    attr_reader :app_permissions

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

    #
    # Initialize a new interaction.
    # @private
    #
    # @param [Discorb::Client] client The client this interaction belongs to.
    # @param [Hash] data The data of the interaction.
    #
    def initialize(client, data)
      @client = client
      @id = Snowflake.new(data[:id])
      @application_id = Snowflake.new(data[:application_id])
      @type = self.class.interaction_name
      @type_id = self.class.interaction_type
      @guild_id = data[:guild_id] && Snowflake.new(data[:guild_id])
      @channel_id = data[:channel_id] && Snowflake.new(data[:channel_id])
      if data[:member]
        @user = guild.members[data[:member][:id]] || Member.new(@client, @guild_id, data[:member][:user],
                                                                data[:member])
      elsif data[:user]
        @user = @client.users[data[:user][:id]] || User.new(@client, data[:user])
      end
      @token = data[:token]
      @locale = data[:locale].to_s.gsub("-", "_").to_sym
      @guild_locale = data[:guild_locale].to_s.gsub("-", "_").to_sym
      @app_permissions = data[:app_permissions] && Permission.new(data[:app_permissions].to_i)
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

    def inspect
      "#<#{self.class} id=#{@id}>"
    end

    class << self
      # @private
      attr_reader :interaction_type, :interaction_name, :event_name

      #
      # Create a new Interaction instance from the data.
      # @private
      #
      # @param [Discorb::Client] client The client this interaction belongs to.
      # @param [Hash] data The data of the interaction.
      #
      def make_interaction(client, data)
        interaction = nil
        descendants.each do |klass|
          if !klass.interaction_type.nil? && klass.interaction_type == data[:type]
            interaction = klass.make_interaction(client,
                                                 data)
          end
        end
        if interaction.nil?
          client.logger.warn("Unknown interaction type #{data[:type]}, initialized Interaction")
          interaction = Interaction.new(client, data)
        end
        interaction
      end

      #
      # Returns the descendants of the class.
      # @private
      #
      def descendants
        ObjectSpace.each_object(Class).select { |klass| klass < self }
      end
    end
  end
end
