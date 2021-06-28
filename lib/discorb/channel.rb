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

    alias_method :category, :parent

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
        payload[:allowed_mentions] = allowed_mentions ? allowed_mentions.to_hash(@client.allowed_mentions) : @client.allowed_mentions.to_hash
        payload[:message_reference] = message_reference.to_reference if message_reference
        if components
          if components.filter { |c| c.is_a? Array }.length == 0
            tmp_components = [components].map { |c| c }
          else
            tmp_components = components.map { |c| c.is_a?(Array) ? c : [c] }
          end
          payload[:components] = tmp_components.map { |c| { "type": 1, "components": c.map(&:to_hash) } }
        end
        Message.new(@client, @client.internet.post("/channels/#{self.id}/messages", payload).wait[1])
      end
    end

    def edit(name: nil, announce: nil, position: nil, topic: nil, nsfw: nil, slowmode: nil, bitrate: nil, category: nil, parent: nil)
      Async do
        payload = {}
        payload[:name] = name if name
        payload[:announce] = announce ? 5 : 0 if announce != nil
        payload[:position] = position if position
        payload[:topic] = topic || "" if topic != nil
        payload[:nsfw] = nsfw if nsfw != nil
        payload[:rate_limit_per_user] = slowmode || 0 if slowmode != nil
        parent ||= category
        payload[:parent_id] = parent.id if parent != nil

        @client.internet.patch("/channels/#{@id}", payload)
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
