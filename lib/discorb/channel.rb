require "time"
require_relative "flag"
require_relative "common"

module Discorb
  class GuildChannel < DiscordModel
    attr_reader :id, :name, :type, :position, :permission_overwrites
    @channel_type = nil

    def initialize(client, data)
      @client = client
      set_data(data)
    end

    def parent
      @client.channels[@parent_id]
    end

    def guild
      @client.guilds[@guild]
    end

    private

    def set_data(data)
      @id = data[:id].to_i
      @name = self.name
      @guild_id = data[:guild_id]
      @position = data[:position]
      @permission_overwrites = nil # TODO: Hash<Discorb::PermissionOverwrite>
      @parent_id = data[:parent_id]
      @client.channels[@id] = self
    end
  end

  class TextChannel < GuildChannel
    attr_reader :topic, :nsfw, :last_message_id, :rate_limit_per_user, :last_pin_timestamp
    @channel_type = 0

    alias_method :slowmode, :rate_limit_per_user

    def post(content = nil, embeds: nil)
      Async do |task|
        @client.internet.post("/channels/#{self.id}/messages", { content: content })
      end
    end

    private

    def set_data(data)
      @topic = data[:topic]
      @nsfw = data[:nsfw]
      @last_message_id = data[:last_message_id]
      @rate_limit_per_user = data[:rate_limit_per_user]
      @last_pin_timestamp = data[:last_pin_timestamp] ? Time.iso8601(data[:last_pin_timestamp]) : nil
      super
    end
  end

  def make_channel(client, data)
    case data[:type]
    when 0
      TextChannel.new(client, data)
    end
  end

  module_function :make_channel
end
