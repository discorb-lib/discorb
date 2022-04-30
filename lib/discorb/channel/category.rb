# frozen_string_literal: true

module Discorb
  #
  # Represents a category in a guild.
  #
  class CategoryChannel < GuildChannel
    @channel_type = 4

    include Discorb::ChannelContainer

    def channels
      @client.channels.values.filter { |channel| channel.parent == self }
    end

    def create_text_channel(*args, **kwargs)
      guild.create_text_channel(*args, parent: self, **kwargs)
    end

    def create_voice_channel(*args, **kwargs)
      guild.create_voice_channel(*args, parent: self, **kwargs)
    end

    def create_news_channel(*args, **kwargs)
      guild.create_news_channel(*args, parent: self, **kwargs)
    end

    def create_stage_channel(*args, **kwargs)
      guild.create_stage_channel(*args, parent: self, **kwargs)
    end
  end
end
