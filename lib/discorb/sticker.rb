# frozen_string_literal: true

module Discorb
  #
  # Represents a sticker.
  #
  class Sticker < DiscordModel
    # @return [Discorb::Snowflake] The ID of the sticker.
    attr_reader :id
    # @return [String] The name of the sticker.
    attr_reader :name
    # @return [Array<String>] The tags of the sticker.
    attr_reader :tags
    # @return [:official, :guild] The type of sticker.
    attr_reader :type
    # @return [:png, :apng, :lottie] The format of the sticker.
    attr_reader :format
    # @return [String] The URL of the sticker.
    attr_reader :description
    # @return [Discorb::Snowflake] The ID of the sticker pack.
    attr_reader :pack_id
    # @return [Integer] The sort value of the sticker.
    attr_reader :sort_value
    # @return [Discorb::Snowflake] The ID of the guild the sticker is in.
    attr_reader :guild_id
    # @return [Discorb::User] The user who created the sticker.
    attr_reader :user
    # @return [Boolean] Whether the sticker is available.
    attr_reader :available
    alias available? available

    # @private
    # @return [{Integer => Symbol}] The mapping of sticker types.
    STICKER_TYPE = {
      1 => :official,
      2 => :guild,
    }.freeze

    # @private
    # @return [{Integer => Symbol}] The mapping of sticker format.
    STICKER_FORMAT = {
      1 => :png,
      2 => :apng,
      3 => :lottie,
    }.freeze
    #
    # Initialize a new sticker.
    # @private
    #
    # @param [Discorb::Client] client The client.
    # @param [Hash] data The sticker data.
    #
    def initialize(client, data)
      @client = client
      _set_data(data)
    end

    #
    # Represents a sticker of guilds.
    #
    class GuildSticker < Sticker
      # @!attribute [r] guild
      #   @macro client_cache
      #   @return [Discorb::Guild] The guild the sticker is in.

      def guild
        @client.guilds[@guild_id]
      end

      #
      # Edits the sticker.
      # @async
      # @macro edit
      #
      # @param [String] name The new name of the sticker.
      # @param [String] description The new description of the sticker.
      # @param [Discorb::Emoji] tag The new tags of the sticker.
      # @param [String] reason The reason for the edit.
      #
      # @return [Async::Task<void>] The task.
      #
      def edit(name: Discorb::Unset, description: Discorb::Unset, tag: Discorb::Unset, reason: Discorb::Unset)
        Async do
          payload = {}
          payload[:name] = name unless name == Discorb::Unset
          payload[:description] = description unless description == Discorb::Unset
          payload[:tags] = tag.name unless tag == Discorb::Unset
          @client.http.request(
            Route.new("/guilds/#{@guild_id}/stickers/#{@id}", "//guilds/:guild_id/stickers/:sticker_id",
                      :patch), payload, audit_log_reason: reason,
          ).wait
        end
      end

      alias modify edit

      #
      # Deletes the sticker.
      # @async
      #
      # @param [String] reason The reason for the deletion.
      #
      def delete(reason: nil)
        Async do
          @client.http.request(
            Route.new("/guilds/#{@guild_id}/stickers/#{@id}", "//guilds/:guild_id/stickers/:sticker_id",
                      :delete), {}, audit_log_reason: reason,
          ).wait
        end
      end

      alias destroy delete
    end

    #
    # Represents a sticker pack.
    #
    class Pack < DiscordModel
      # @return [Discorb::Snowflake] The ID of the sticker pack.
      attr_reader :id
      # @return [String] The name of the sticker pack.
      attr_reader :name
      # @return [Discorb::Snowflake] The cover sticker of the pack.
      attr_reader :cover_sticker_id
      # @return [String] The description of the pack.
      attr_reader :description
      # @return [Array<Discorb::Sticker>] The stickers in the pack.
      attr_reader :stickers
      # @return [Discorb::Asset] The banner of the pack.
      attr_reader :banner

      #
      # Initialize a new sticker pack.
      # @private
      #
      # @param [Discorb::Client] client The client.
      # @param [Hash] data The sticker pack data.
      #
      def initialize(client, data)
        @client = client
        @id = Snowflake.new(data[:id])
        @name = data[:name]
        @sku_id = Snowflake.new(data[:sku_id])
        @cover_sticker_id = Snowflake.new(data[:cover_sticker_id])
        @description = data[:description]
        @banner_asset_id = Snowflake.new(data[:banner_asset_id])
        @banner = Asset.new(self, data[:banner_asset_id], path: "app-assets/710982414301790216/store")
        @stickers = data[:stickers].map { |s| Sticker.new(@client, s) }
      end
    end

    private

    def _set_data(data)
      @id = Snowflake.new(data[:id])
      @name = data[:name]
      @tags = data[:tags].split(",")
      @type = STICKER_TYPE[data[:type]]
      @format = STICKER_FORMAT[data[:format]]
      @description = data[:description]
      @available = data[:available]
      if @type == :official
        @pack_id = Snowflake.new(data[:guild_id])
        @sort_value = data[:sort_value]
      else
        @guild_id = Snowflake.new(data[:guild_id])
        @user = data[:user] && (@client.users[data[:user][:id]] || User.new(@client, data[:user]))
      end
    end
  end
end
