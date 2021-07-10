# frozen_string_literal: true

require 'uri'
require_relative 'common'
require_relative 'user'
require_relative 'guild'
require_relative 'emoji_table'

module Discorb
  class CustomEmoji < DiscordModel
    attr_reader :id, :name, :roles, :user, :require_colons, :guild, :data

    def initialize(client, guild, data)
      @client = client
      @guild = guild
      @_data = {}
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

    # @!visibility private
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
      @_data.update(data)
    end
  end

  class UnicodeEmoji
    def initialize(name)
      @name = name
      @value = DISCORD_TO_UNICODE[name] or name
    end

    def to_s
      @value
    end

    def to_uri
      URI.encode_www_form_component(@value)
    end

    def self.[](...)
      new(...)
    end
  end
end
