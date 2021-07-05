# frozen_string_literal: true

require_relative 'emoji'

module Discorb
  class Component
    class << self
      def from_hash(data)
        case data[:type]
        when 2
          Button.new(
            data[:label],
            data[:style],
            emoji: data[:emoji],
            custom_id: data[:custom_id],
            url: data[:url],
            disabled: data[:disabled]
          )
        when 3
          SelectMenu.new(
            data[:custom_id],
            data[:options].map { |o| SelectMenu::Option.from_hash(o) },
            placeholder: data[:placeholder],
            min_values: data[:min_values],
            max_values: data[:max_values]
          )
        end
      end
    end
  end

  class Button < Component
    attr_accessor :label, :style, :emoji, :custom_id, :url, :disabled

    @styles = {
      primary: 1,
      secondary: 2,
      success: 3,
      danger: 4,
      link: 5
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
          style: self.class.styles[@style],
          url: @url,
          emoji: hash_emoji(@emoji),
          disabled: @disabled
        }
      else
        {
          type: 2,
          label: @label,
          style: self.class.styles[@style],
          custom_id: @custom_id,
          emoji: hash_emoji(@emoji),
          disabled: @disabled
        }
      end
    end

    def self.[](...)
      new(...)
    end

    class << self
      attr_reader :styles
    end

    private

    def hash_emoji(emoji)
      case emoji
      when UnicodeEmoji
        {
          id: nil,
          name: emoji.to_s,
          animated: false
        }
      when CustomEmoji
        {
          id: emoji.id,
          name: emoji.name,
          animated: emoji.animated?
        }
      end
    end
  end

  class SelectMenu < Component
    attr_accessor :custom_id, :options, :position, :min_values, :max_values

    def initialize(custom_id, options, placeholder: nil, min_values: 1, max_values: 1)
      @custom_id = custom_id
      @options = options
      @placeholder = placeholder
      @min_values = min_values
      @max_values = max_values
    end

    def disabled?
      @disabled
    end

    def to_hash
      {
        type: 3,
        custom_id: @custom_id,
        options: @options.map(&:to_hash),
        placeholder: @placeholder,
        min_values: @min_values,
        max_values: @max_values
      }
    end

    class Option
      attr_accessor :label, :value, :description, :emoji, :default

      def initialize(label, value, description: nil, emoji: nil, default: false)
        @label = label
        @value = value
        @description = description
        @emoji = emoji
        @default = default
      end

      def to_hash
        {
          label: @label,
          value: @value,
          description: @description,
          emoji: hash_emoji(@emoji),
          default: @default
        }
      end

      def hash_emoji(emoji)
        case emoji
        when UnicodeEmoji
          {
            id: nil,
            name: emoji.to_s,
            animated: false
          }
        when CustomEmoji
          {
            id: emoji.id,
            name: emoji.name,
            animated: emoji.animated?
          }
        end
      end

      class << self
        def from_hash(data)
          new(data[:label], data[:value], description: data[:description], emoji: data[:emoji], default: data[:default])
        end
      end
    end

    def self.[](...)
      new(...)
    end

    private

    def hash_emoji(emoji)
      case emoji
      when UnicodeEmoji
        {
          id: nil,
          name: emoji.to_s,
          animated: false
        }
      when CustomEmoji
        {
          id: emoji.id,
          name: emoji.name,
          animated: emoji.animated?
        }
      end
    end
  end
end
