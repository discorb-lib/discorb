# frozen_string_literal: true

require 'uri'
require_relative 'common'
require_relative 'user'
require_relative 'guild'
require_relative 'emoji_table'

module Discorb
  class CustomEmoji < DiscordModel
    attr_reader :id, :name, :roles, :user, :require_colons, :guild

    def initialize(client, guild, data)
      @client = client
      @guild = guild
      @data = {}
      _set_data(data)
    end

    def to_s
      "<#{@animated ? 'a' : ''}:#{@name}:#{id}>"
    end

    def to_uri
      "#{@name}:#{@id}"
    end

    def managed?
      @managed
    end

    def animated?
      @animated
    end

    def available?
      @available
    end

    def roles?
      @roles != []
    end

    def inspect
      "#<#{self.class} id=#{@id} :#{@name}:>"
    end

    def edit(name: :unset, roles: :unset, reason: nil)
      Async do
        payload = {}
        payload[:name] = name if name != :unset
        payload[:roles] = roles.map { |r| Discorb::Utils.try(r, :id) } if roles != :unset
        @client.internet.patch("/guilds/#{@guild.id}/emojis/#{@id}", payload, audit_log_reason: reason)
      end
    end
    alias modify edit

    def delete!(reason: nil)
      Async do
        @client.internet.delete("/guilds/#{@guild.id}/emojis/#{@id}", audit_log_reason: reason).wait
        @available = false
        self
      end
    end

    alias destroy! delete!

    private

    def _set_data(data)
      @id = Snowflake.new(data[:id])
      @name = data[:name]
      @roles = data[:role] ? data[:role].map { |r| Role.new(@client, r) } : []
      @user = User.new(@client, data[:user]) if data[:user]
      @require_colons = data[:require_colons]
      @managed = data[:managed]
      @animated = data[:animated]
      @available = data[:available]
      @guild.emojis[@id] = self unless data[:no_cache]
      @data.update(data)
    end
  end

  class PartialEmoji < DiscordModel
    attr_reader :id, :name

    def initialize(data)
      @id = Snowflake.new(data[:id])
      @name = data[:name]
      @animated = data[:animated]
      @deleted = @name.nil?
    end

    def deleted?
      @deleted
    end

    def to_uri
      "#{@name}:#{@id}"
    end

    def inspect
      "#<#{self.class} id=#{@id} :#{@name}:>"
    end

    def to_s
      "<#{@animated ? 'a' : ''}:#{@name}:#{@id}>"
    end
  end

  class UnicodeEmoji
    attr_reader :name, :value

    def initialize(name)
      if EmojiTable::DISCORD_TO_UNICODE.key?(name)
        @name = name
        @value = EmojiTable::DISCORD_TO_UNICODE[name]
      elsif EmojiTable::UNICODE_TO_DISCORD.key?(name)
        @name = EmojiTable::UNICODE_TO_DISCORD[name][0]
        @value = name
      else
        raise ArgumentError, "No such emoji: #{name}"
      end
    end

    def to_s
      @value
    end

    def to_uri
      URI.encode_www_form_component(@value)
    end

    def inspect
      "#<#{self.class} :#{@name}:>"
    end

    class << self
      alias [] new
    end
  end
end
