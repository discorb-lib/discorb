# frozen_string_literal: true

require "uri"

module Discorb
  # Represents a Discord emoji.
  # @abstract
  class Emoji
    def eql?(other)
      other.is_a?(self.class) && other.to_uri == to_uri
    end

    def ==(other)
      eql?(other)
    end

    def inspect
      "#<#{self.class}>"
    end
  end

  # Represents a custom emoji in discord.
  class CustomEmoji < Emoji
    # @return [Discorb::Snowflake] The ID of the emoji.
    attr_reader :id
    # @return [String] The name of the emoji.
    attr_reader :name
    # @return [Array<Discorb::Role>] The roles that can use this emoji.
    attr_reader :roles
    # @return [Discorb::User] The user that created this emoji.
    attr_reader :user
    # @return [Boolean] Whether the emoji requires colons.
    attr_reader :guild
    # @return [Boolean] whether the emoji is managed by integration (ex: Twitch).
    attr_reader :managed
    alias managed? managed
    # @return [Boolean] whether the emoji requires colons.
    attr_reader :require_colons
    alias require_colons? require_colons
    # @return [Boolean] whether the emoji is available.
    attr_reader :available
    alias available? available

    # @!attribute [r] roles?
    #   @return [Boolean] whether or not this emoji is restricted to certain roles.

    # @private
    def initialize(client, guild, data)
      @client = client
      @guild = guild
      @data = {}
      _set_data(data)
    end

    #
    # Format the emoji for sending.
    #
    # @return [String] the formatted emoji.
    #
    def to_s
      "<#{@animated ? "a" : ""}:#{@name}:#{id}>"
    end

    #
    # Format the emoji for URI.
    #
    # @return [String] the formatted emoji.
    #
    def to_uri
      "#{@name}:#{@id}"
    end

    def roles?
      @roles != []
    end

    alias role? roles?

    def inspect
      "#<#{self.class} id=#{@id} :#{@name}:>"
    end

    #
    # Edit the emoji.
    # @async
    # @macro edit
    #
    # @param [String] name The new name of the emoji.
    # @param [Array<Discorb::Role>] roles The new roles that can use this emoji.
    # @param [String] reason The reason for editing the emoji.
    #
    # @return [Async::Task<self>] The edited emoji.
    #
    def edit(name: Discorb::Unset, roles: Discorb::Unset, reason: nil)
      Async do
        payload = {}
        payload[:name] = name if name != Discorb::Unset
        payload[:roles] = roles.map { |r| Discorb::Utils.try(r, :id) } if roles != Discorb::Unset
        @client.http.request(Route.new("/guilds/#{@guild.id}/emojis/#{@id}", "//guilds/:guild_id/emojis/:emoji_id", :patch), payload, audit_log_reason: reason)
        self
      end
    end

    alias modify edit

    #
    # Delete the emoji.
    # @async
    #
    # @param [String] reason The reason for deleting the emoji.
    #
    # @return [Async::Task<self>] The deleted emoji.
    #
    def delete!(reason: nil)
      Async do
        @client.http.request(Route.new("/guilds/#{@guild.id}/emojis/#{@id}", "//guilds/:guild_id/emojis/:emoji_id", :delete), audit_log_reason: reason).wait
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

  #
  # Represents a partial custom emoji in discord.
  #
  class PartialEmoji < DiscordModel
    # @return [Discorb::Snowflake] The ID of the emoji.
    attr_reader :id
    # @return [String] The name of the emoji.
    attr_reader :name
    # @return [Boolean] Whether the emoji is deleted.
    attr_reader :deleted
    alias deleted? deleted

    # @private
    def initialize(data)
      @id = Snowflake.new(data[:id])
      @name = data[:name]
      @animated = data[:animated]
      @deleted = @name.nil?
    end

    #
    # Format the emoji for URI.
    #
    # @return [String] the formatted emoji.
    #
    def to_uri
      "#{@name}:#{@id}"
    end

    def inspect
      "#<#{self.class} id=#{@id} :#{@name}:>"
    end

    #
    # Format the emoji for sending.
    #
    # @return [String] the formatted emoji.
    #
    def to_s
      "<#{@animated ? "a" : ""}:#{@name}:#{@id}>"
    end
  end

  #
  # Represents a unicode emoji (default emoji) in discord.
  #
  class UnicodeEmoji < Emoji
    # @return [String] The name of the emoji. (e.g. :grinning:)
    attr_reader :name
    # @return [String] The unicode value of the emoji. (e.g. U+1F600)
    attr_reader :value
    # @return [Integer] The skin tone of the emoji.
    attr_reader :skin_tone

    # @private
    def initialize(name, tone: 0)
      if EmojiTable::DISCORD_TO_UNICODE.key?(name)
        @name = name
        @value = EmojiTable::DISCORD_TO_UNICODE[name]
      elsif EmojiTable::UNICODE_TO_DISCORD.key?(name)
        @name = EmojiTable::UNICODE_TO_DISCORD[name][0]
        @value = name
      else
        raise ArgumentError, "No such emoji: #{name}"
      end
      @value += EmojiTable::SKIN_TONES[tone] if tone.positive?
    end

    # @return [String] The unicode string of the emoji.
    def to_s
      @value
    end

    #
    # Format the emoji for URI.
    #
    # @return [String] the formatted emoji.
    #
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
