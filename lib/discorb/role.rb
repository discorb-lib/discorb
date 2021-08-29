# frozen_string_literal: true

module Discorb
  #
  # Represents a role in the guild.
  #
  class Role < DiscordModel
    # @return [Discorb::Snowflake] The ID of the role.
    attr_reader :id
    # @return [String] The name of the role.
    attr_reader :name
    # @return [Discorb::Color] The color of the role.
    attr_reader :color
    # @return [Discorb::Permission] The permissions of the role.
    attr_reader :permissions
    # @return [Integer] The position of the role.
    attr_reader :position
    # @return [Discorb::Guild] The guild this role belongs to.
    attr_reader :guild
    # @return [Boolean] Whether the role is hoisted.
    attr_reader :hoist
    alias hoist? hoist
    # @return [Boolean] Whether the role is managed.
    attr_reader :managed
    alias managed? managed
    # @return [Boolean] Whether the role is a default role.
    attr_reader :mentionable
    alias mentionable? mentionable

    # @!attribute [r] mention
    #   @return [String] The mention of the role.
    # @!attribute [r] color?
    #   @return [Boolean] Whether the role has a color.
    # @!attribute [r] tag
    #   @return [Discorb::Role::Tag] The tag of the role.

    include Comparable

    # @!visibility private
    def initialize(client, guild, data)
      @client = client
      @guild = guild
      @data = {}
      _set_data(data)
    end

    #
    # Compares two roles by their position.
    #
    # @param [Discorb::Role] other The role to compare to.
    #
    # @return [Integer] -1 if the other role is higher, 0 if they are equal, 1 if the other role is lower.
    #
    def <=>(other)
      return false unless other.is_a?(Role)

      @position <=> other.position
    end

    #
    # Formats the role as a string.
    #
    # @return [String] The formatted string.
    #
    def to_s
      "@#{@name}"
    end

    def mention
      "<@&#{@id}>"
    end

    def color?
      @color != 0
    end

    def inspect
      "#<#{self.class} @#{@name} id=#{@id}>"
    end

    #
    # Moves the role to a new position.
    # @macro async
    # @macro http
    #
    # @param [Integer] position The new position.
    # @param [String] reason The reason for moving the role.
    #
    def move(position, reason: nil)
      Async do
        @client.http.patch("/guilds/#{@guild_id}/roles", { id: @id, position: position }, reason: reason).wait
      end
    end

    #
    # Edits the role.
    # @macro async
    # @macro http
    # @macro edit
    #
    # @param [String] name The new name of the role.
    # @param [Integer] position The new position of the role.
    # @param [Discorb::Color] color The new color of the role.
    # @param [Boolean] hoist Whether the role should be hoisted.
    # @param [Boolean] mentionable Whether the role should be mentionable.
    # @param [String] reason The reason for editing the role.
    #
    def edit(name: :unset, position: :unset, color: :unset, hoist: :unset, mentionable: :unset, reason: nil)
      Async do
        payload = {}
        payload[:name] = name if name != :unset
        payload[:position] = position if position != :unset
        payload[:color] = color.to_i if color != :unset
        payload[:hoist] = hoist if hoist != :unset
        payload[:mentionable] = mentionable if mentionable != :unset
        @client.http.patch("/guilds/#{@guild_id}/roles/#{@id}", payload, reason: reason).wait
      end
    end

    alias modify edit

    #
    # Deletes the role.
    #
    # @param [String] reason The reason for deleting the role.
    #
    def delete!(reason: nil)
      Async do
        @client.http.delete("/guilds/#{@guild_id}/roles/#{@id}", reason: reason).wait
      end
    end

    alias destroy! delete!

    def tag
      Tag.new(@tags)
    end

    alias tags tag

    #
    # Represents a tag of a role.
    #
    class Tag < DiscordModel
      # @return [Discorb::Snowflake] The ID of the bot that owns the role.
      attr_reader :bot_id
      # @return [Discorb::Snowflake] The ID of the integration.
      attr_reader :integration_id
      # @return [Boolean] Whether the tag is a premium subscriber role.
      attr_reader :premium_subscriber
      alias premium_subscriber? premium_subscriber
      # @!attribute [r] bot?
      #   @return [Boolean] Whether the role is a bot role.
      # @!attribute [r] integration?
      #   @return [Boolean] Whether the role is an integration role.

      # @!visibility private
      def initialize(data)
        @bot_id = Snowflake.new(data[:bot_id])
        @integration_id = Snowflake.new(data[:integration_id])
        @premium_subscriber = data.key?(:premium_subscriber)
      end

      def bot?
        !@bot_id.nil?
      end

      def integration?
        !@integration_id.nil?
      end
    end

    private

    def _set_data(data)
      @id = Snowflake.new(data[:id])
      @name = data[:name]
      @color = Color.new(data[:color])
      @hoist = data[:hoist]
      @position = data[:position]
      @permissions = Permission.new(data[:permissions].to_i)
      @managed = data[:managed]
      @mentionable = data[:mentionable]
      @tags = data[:tags] || {}
      @guild.roles[@id] = self unless data[:no_cache]
      @data.update(data)
    end
  end
end
