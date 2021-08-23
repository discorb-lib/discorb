# frozen_string_literal: true

module Discorb
  class Sticker < DiscordModel
    attr_reader :id, :name, :tags, :type, :format, :description, :pack_id, :sort_value, :guild_id, :user, :available
    alias available? available

    @sticker_type = {
      1 => :official,
      2 => :guild
    }.freeze
    @sticker_format = {
      1 => :png,
      2 => :apng,
      3 => :lottie
    }
    # @!visibility private
    def initialize(client, data)
      @client = client
      _set_data(data)
    end

    class GuildSticker < Sticker
      def guild
        @client.guilds[@guild_id]
      end

      def edit(name: nil, description: nil, tag: nil, reason: nil)
        Async do
          payload = {}
          payload[:name] = name if name
          payload[:description] = description if description
          payload[:tags] = tag.name if tag
          @client.internet.patch("/guilds/#{@guild_id}/stickers/#{@id}", payload, audit_log_reason: reason).wait
        end
      end

      alias modify edit

      def delete!(reason: nil)
        Async do
          @client.internet.delete("/guilds/#{@guild_id}/stickers/#{@id}", audit_log_reason: reason).wait
        end
      end

      alias destroy! delete!
    end

    class Pack < DiscordModel
      attr_reader :id, :name, :sku_id, :cover_sticker_id, :description, :banner_asset_id, :stickers, :banner

      def initialize(client, data)
        @client = client
        @id = Snowflake.new(data[:id])
        @name = data[:name]
        @sku_id = Snowflake.new(data[:sku_id])
        @cover_sticker_id = Snowflake.new(data[:cover_sticker_id])
        @description = data[:description]
        @banner_asset_id = Snowflake.new(data[:banner_asset_id])
        @banner = Asset.new(self, data[:banner_asset_id], path: 'app-assets/710982414301790216/store')
        @stickers = data[:stickers].map { |s| Sticker.new(@client, s) }
      end
    end

    private

    def _set_data(data)
      @id = Snowflake.new(data[:id])
      @name = data[:name]
      @tags = data[:tags].split(',')
      @type = self.class.sticker_type[data[:type]]
      @format = self.class.sticker_format[data[:format]]
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

    class << self
      attr_reader :sticker_type, :sticker_format
    end
  end
end
