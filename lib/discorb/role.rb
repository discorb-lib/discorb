# frozen_string_literal: true

require_relative 'common'

module Discorb
  class Role < DiscordModel
    attr_reader :id, :name, :color, :permissions, :position, :guild

    include Comparable
    def initialize(client, guild, data)
      @client = client
      @guild = guild
      @_data = {}
      _set_data(data)
    end

    def <=>(other)
      @position <=> other.position
    end

    def to_s
      "<@&#{@id}>"
    end

    def color?
      @color != 0
    end

    def hoist?
      @hoist
    end

    def managed?
      @managed
    end

    def mentionable?
      @mentionable
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

    class Tag
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

    # @!visibility private
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
      @_data.update(data)
    end
  end
end
