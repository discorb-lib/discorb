require "uri"
require_relative "common"
require_relative "user"
require_relative "emoji_table"

module Discorb
  class CustomEmoji < DiscordModel
    attr_reader :id, :name, :roles, :user, :require_colons

    def initialize(client, data)
      @client = client
      set_data(data)
    end

    def to_s
      if @unicode
        @name
      else
        "<#{@animated ? "a" : ""}:#{@name}:#{id}"
      end
    end

    def to_uri
      if @unicode
        URI.encode @name
      else
        @name + ":" + @id
      end
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

    def self.[](...)
      self.from_discord_name(...)
    end

    private

    def set_data(data)
      @id = data[:id].to_i
      @name = data[:name]
      @roles = nil # TODO: Array<Discorb::Role>
      @user = User.new(@client, data[:user])
      @require_colons = data[:require_colons]
      @managed = data[:managed]
      @animated = data[:animated]
      @available = data[:available]
    end
  end

  class UnicodeEmoji
    def initialize(name)
      @name = name
      @value = DISCORD_TO_UNICODE[name]
    end

    def to_s
      @value
    end

    def to_uri
      URI.encode_www_form_component(@value)
    end

    def self.[](...)
      self.new(...)
    end
  end
end
