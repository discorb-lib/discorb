require "time"
require_relative "flag"
require_relative "common"

module Discorb
  class GuildChannel < DiscordModel
    attr_reader :id, :name, :type, :position, :permission_overwrites
    include Comparable
    @channel_type = nil

    def initialize(client, data)
      @client = client
      set_data(data)
    end

    def ==(other)
      @id == other.id
    end

    def <=>(other)
      @position <=> other.position
    end

    def parent
      return nil if not @parent_id
      @client.channels[@parent_id]
    end

    def guild
      @client.guilds[@guild]
    end

    def inspect
      "#<#{self.class} \"##{@name}\" id=#{@id}>"
    end

    private

    def set_data(data)
      @id = data[:id].to_i
      @name = self.name
      @guild_id = data[:guild_id]
      @position = data[:position]
      @permission_overwrites = nil # TODO: Hash<Discorb::PermissionOverwrite>
      @parent_id = data[:parent_id]
      @client.channels[@parent_id]&.channels&.push(self) if @parent_id != nil

      @client.channels[@id] = self
    end
  end

  class TextChannel < GuildChannel
    attr_reader :topic, :nsfw, :last_message_id, :rate_limit_per_user, :last_pin_timestamp
    @channel_type = 0

    alias_method :slowmode, :rate_limit_per_user

    def post(content = nil, tts: false, embed: nil, embeds: nil, allowed_mentions: nil, message_reference: nil, components: nil)
      Async do |task|
        payload = {}
        payload[:content] = content if content
        payload[:tts] = tts
        tmp_embed = if embed
            [embed]
          elsif embeds
            embeds
          else
            nil
          end
        payload[:embeds] = tmp_embed.map(&:to_hash) if tmp_embed
        payload[:allowed_mentions] = allowed_mentions.to_hash if allowed_mentions
        Message.new(@client, @client.internet.post("/channels/#{self.id}/messages", payload).wait[1])
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

  class VoiceChannel < GuildChannel
    attr_reader :bitrate, :user_limit
    @channel_type = 2

    private

    def set_data(data)
      @bitrate = data[:bitrate]
      @user_limit = data[:user_limit]
      super
    end
  end

  class CategoryChannel < GuildChannel
    attr_reader :channels

    def initialize(resp, data)
      super
    end

    def voice_channels
    end

    private

    def set_data()
      super
      @channels = @client.channels.value.filter { |channel| channel.parent == self }
    end
  end

  def make_channel(client, data)
    case data[:type]
    when 0
      TextChannel.new(client, data)
    when 2
      VoiceChannel.new(client, data)
    end
  end

  module_function :make_channel
end
