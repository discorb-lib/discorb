# frozen_string_literal: true

module Discorb
  class Role < DiscordModel
    attr_reader :id, :name, :color, :permissions, :position, :guild, :hoist, :managed, :mentionable

    include Comparable
    def initialize(client, guild, data)
      @client = client
      @guild = guild
      @data = {}
      _set_data(data)
    end

    def <=>(other)
      @position <=> other.position
    end

    def to_s
      "@#{@name}"
    end

    def mention
      "<@&#{@id}>"
    end

    def color?
      @color != 0
    end

    def update!
      Async do
        _resp, data = @client.internet.get("/guilds/#{@guild_id}/roles").wait
        _set_data(data.find { |r| r[:id] == @id })
      end
    end

    def inspect
      "#<#{self.class} @#{@name} id=#{@id}>"
    end

    def move(position, reason: nil)
      Async do
        @client.internet.patch("/guilds/#{@guild_id}/roles", { id: @id, position: position }, reason: reason).wait
      end
    end

    def edit(name: :unset, position: :unset, color: :unset, hoist: :unset, mentionable: :unset, reason: nil)
      Async do
        payload = {}
        payload[:name] = name if name != :unset
        payload[:position] = position if position != :unset
        payload[:color] = color.to_i if color != :unset
        payload[:hoist] = hoist if hoist != :unset
        payload[:mentionable] = mentionable if mentionable != :unset
        @client.internet.patch("/guilds/#{@guild_id}/roles/#{@id}", payload, reason: reason).wait
      end
    end

    alias modify edit

    def delete!(reason: nil)
      Async do
        @client.internet.delete("/guilds/#{@guild_id}/roles/#{@id}", reason: reason).wait
      end
    end

    alias destroy! delete!

    def tag
      Tag.new(@tags)
    end

    alias tags tag

    class Tag < DiscordModel
      attr_reader :bot_id, :integration_id, :premium_subscriber

      def initialize(data)
        @bot_id = Snowflake.new(data[:bot_id])
        @integration_id = Snowflake.new(data[:bot_id])
        @premium_subscriber = Snowflake.new(data[:bot_id])
      end

      def bot?
        !@bot_id.nil?
      end

      def integration?
        !@integration_id.nil?
      end

      def premium_subscriber?
        !!@premium_subscriber
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
