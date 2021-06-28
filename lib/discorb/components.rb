require_relative "emoji"

module Discorb
  class Button
    attr_accessor :label, :style, :emoji, :custom_id, :url, :disabled
    @@styles = {
      primary: 1,
      secondary: 2,
      success: 3,
      danger: 4,
      link: 5,
    }

    def initialize(label, style = :primary, emoji: nil, custom_id: nil, url: nil, disabled: false)
      @label = label
      @style = style
      @emoji = emoji
      @custom_id = custom_id
      @url = url
      @disabled = disabled
    end

    def disabled?
      @disabled
    end

    def to_hash
      if @style == :link
        {
          type: 2,
          label: @label,
          style: @@styles[@style],
          url: @url,
          emoji: hash_emoji(@emoji),
          disabled: @disabled,
        }
      else
        {
          type: 2,
          label: @label,
          style: @@styles[@style],
          custom_id: @custom_id,
          emoji: hash_emoji(@emoji),
          disabled: @disabled,
        }
      end
    end

    def self.[](...)
      self.new(...)
    end

    private

    def hash_emoji(emoji)
      if emoji.is_a? UnicodeEmoji
        {
          id: nil,
          name: emoji.to_s,
          animated: false,
        }
      elsif emoji.is_a? CustomEmoji
        {
          id: emoji.id,
          name: emoji.name,
          animated: emoji.animated?,
        }
      end
    end
  end
end
