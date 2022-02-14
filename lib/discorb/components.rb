# frozen_string_literal: true

module Discorb
  #
  # @abstract
  # Represents a Discord component.
  #
  class Component
    def inspect
      "#<#{self.class}>"
    end

    class << self
      #
      # Create a new component from hash data.
      #
      # @see https://discord.com/developers/docs/interactions/message-components Official Discord API documentation
      # @param [Hash] data Hash data.
      #
      # @return [Component] A new component.
      #
      def from_hash(data)
        case data[:type]
        when 2
          Button.new(
            data[:label],
            data[:style],
            emoji: data[:emoji],
            custom_id: data[:custom_id],
            url: data[:url],
            disabled: data[:disabled],
          )
        when 3
          SelectMenu.new(
            data[:custom_id],
            data[:options].map { |o| SelectMenu::Option.from_hash(o) },
            placeholder: data[:placeholder],
            min_values: data[:min_values],
            max_values: data[:max_values],
          )
        when 4
          TextInput.new(
            data[:custom_id],
            data[:options].map { |o| SelectMenu::Option.from_hash(o) },
            placeholder: data[:placeholder],
            min_values: data[:min_values],
            max_values: data[:max_values],
          )
        end
      end

      #
      # Convert components to a hash.
      #
      # @param [Array<Discorb::Component>, Array<Array<Discorb::Component>>] components Components.
      #
      # @return [Array<Hash>] Hash data.
      #
      def to_payload(components)
        tmp_components = []
        tmp_row = []
        components.each do |c|
          case c
          when Array
            tmp_components << tmp_row
            tmp_row = []
            tmp_components << c
          when SelectMenu, TextInput
            tmp_components << tmp_row
            tmp_row = []
            tmp_components << [c]
          else
            tmp_row << c
          end
        end
        tmp_components << tmp_row
        tmp_components.filter { |c| c.length.positive? }.map { |c| { type: 1, components: c.map(&:to_hash) } }
      end
    end
  end

  #
  # Represents a button component.
  #
  class Button < Component
    # @return [String] The label of the button.
    attr_accessor :label
    # @return [:primary, :secondary, :success, :danger, :link] The style of the button.
    attr_accessor :style
    # @return [Discorb::Emoji] The emoji of the button.
    attr_accessor :emoji
    # @return [String] The custom ID of the button.
    #   Won't be used if the style is `:link`.
    attr_accessor :custom_id
    # @return [String] The URL of the button.
    #   Only used when the style is `:link`.
    attr_accessor :url
    # @return [Boolean] Whether the button is disabled.
    attr_accessor :disabled
    alias disabled? disabled

    @styles = {
      primary: 1,
      secondary: 2,
      success: 3,
      danger: 4,
      link: 5,
    }.freeze

    #
    # Initialize a new button.
    #
    # @param [String] label The label of the button.
    # @param [:primary, :secondary, :success, :danger, :link] style The style of the button.
    # @param [Discorb::Emoji] emoji The emoji of the button.
    # @param [String] custom_id The custom ID of the button.
    # @param [String] url The URL of the button.
    # @param [Boolean] disabled Whether the button is disabled.
    #
    def initialize(label, style = :primary, emoji: nil, custom_id: nil, url: nil, disabled: false)
      @label = label
      @style = style
      @emoji = emoji
      @custom_id = custom_id
      @url = url
      @disabled = disabled
    end

    #
    # Converts the button to a hash.
    #
    # @see https://discord.com/developers/docs/interactions/message-components#button-object-button-structure Official Discord API docs
    # @return [Hash] A hash representation of the button.
    #
    def to_hash
      if @style == :link
        {
          type: 2,
          label: @label,
          style: self.class.styles[@style],
          url: @url,
          emoji: hash_emoji(@emoji),
          disabled: @disabled,
        }
      else
        {
          type: 2,
          label: @label,
          style: self.class.styles[@style],
          custom_id: @custom_id,
          emoji: hash_emoji(@emoji),
          disabled: @disabled,
        }
      end
    end

    def inspect
      "#<#{self.class}: #{@custom_id || @url}>"
    end

    class << self
      # @private
      attr_reader :styles
    end

    private

    def hash_emoji(emoji)
      case emoji
      when UnicodeEmoji
        {
          id: nil,
          name: emoji.to_s,
          animated: false,
        }
      when CustomEmoji
        {
          id: emoji.id,
          name: emoji.name,
          animated: emoji.animated?,
        }
      end
    end
  end

  #
  # Represents a select menu component.
  #
  class SelectMenu < Component
    # @return [String] The custom ID of the select menu.
    attr_accessor :custom_id
    # @return [Array<SelectMenu::Option>] The options of the select menu.
    attr_accessor :options
    # @return [Integer] The minimum number of values.
    attr_accessor :min_values
    # @return [Integer] The maximum number of values.
    attr_accessor :max_values
    # @return [Boolean] Whether the select menu is disabled.
    attr_accessor :disabled
    alias disabled? disabled

    #
    # Initialize a new select menu.
    #
    # @param [String, Symbol] custom_id Custom ID of the select menu.
    # @param [Array<Discorb::SelectMenu::Option>] options The options of the select menu.
    # @param [String] placeholder The placeholder of the select menu.
    # @param [Integer] min_values The minimum number of values.
    # @param [Integer] max_values The maximum number of values.
    #
    def initialize(custom_id, options, placeholder: nil, min_values: 1, max_values: 1)
      @custom_id = custom_id
      @options = options
      @placeholder = placeholder
      @min_values = min_values
      @max_values = max_values
    end

    #
    # Converts the select menu to a hash.
    #
    # @see https://discord.com/developers/docs/interactions/message-components#select-menu-object-select-menu-structure Official Discord API docs
    # @return [Hash] A hash representation of the select menu.
    #
    def to_hash
      {
        type: 3,
        custom_id: @custom_id,
        options: @options.map(&:to_hash),
        placeholder: @placeholder,
        min_values: @min_values,
        max_values: @max_values,
        disabled: @disabled,
      }
    end

    def inspect
      "#<#{self.class}: #{@custom_id}>"
    end

    #
    # Represents an option of a select menu.
    #
    class Option
      # @return [String] The label of the option.
      attr_accessor :label
      # @return [String] The value of the option.
      attr_accessor :value
      # @return [String] The description of the option.
      attr_accessor :description
      # @return [Discorb::Emoji] The emoji of the option.
      attr_accessor :emoji
      # @return [Boolean] Whether the option is default.
      attr_accessor :default

      #
      # Initialize a new option.
      #
      # @param [String] label The label of the option.
      # @param [String] value The value of the option.
      # @param [String] description The description of the option.
      # @param [Discorb::Emoji] emoji The emoji of the option.
      # @param [Boolean] default Whether the option is default.
      def initialize(label, value, description: nil, emoji: nil, default: false)
        @label = label
        @value = value
        @description = description
        @emoji = emoji
        @default = default
      end

      #
      # Converts the option to a hash.
      #
      # @see https://discord.com/developers/docs/interactions/message-components#select-menu-object-select-option-structure Official Discord API docs
      # @return [Hash] Hash representation of the option.
      #
      def to_hash
        {
          label: @label,
          value: @value,
          description: @description,
          emoji: hash_emoji(@emoji),
          default: @default,
        }
      end

      # @private
      def hash_emoji(emoji)
        case emoji
        when UnicodeEmoji
          {
            id: nil,
            name: emoji.to_s,
            animated: false,
          }
        when CustomEmoji
          {
            id: emoji.id,
            name: emoji.name,
            animated: emoji.animated?,
          }
        end
      end

      class << self
        #
        # Creates a new option from a hash.
        #
        # @param [Hash] data A hash representing the option.
        #
        # @return [Discorb::SelectMenu::Option] A new option.
        #
        def from_hash(data)
          new(data[:label], data[:value], description: data[:description], emoji: data[:emoji], default: data[:default])
        end
      end
    end

    private

    def hash_emoji(emoji)
      case emoji
      when UnicodeEmoji
        {
          id: nil,
          name: emoji.to_s,
          animated: false,
        }
      when CustomEmoji
        {
          id: emoji.id,
          name: emoji.name,
          animated: emoji.animated?,
        }
      end
    end
  end

  #
  # Represents a text input component.
  #
  class TextInput < Component
    # @private
    STYLES = {
      short: 1,
      paragraph: 2,
    }.freeze

    # @return [String] The label of the text input.
    attr_accessor :label
    # @return [String] The custom id of the text input.
    attr_accessor :custom_id
    # @return [:short, :paragraph] The style of the text input.
    attr_accessor :style
    # @return [Integer, nil] The minimum length of the text input.
    attr_accessor :min_length
    # @return [Integer, nil] The maximum length of the text input.
    attr_accessor :max_length
    # @return [Boolean] Whether the text input is required.
    attr_accessor :required
    # @return [String, nil] The prefilled value of the text input.
    attr_accessor :value
    # @return [String, nil] The placeholder of the text input.
    attr_accessor :placeholder

    #
    # Initialize a new text input component.
    #
    # @param [String] label The label of the text input.
    # @param [String] custom_id The custom id of the text input.
    # @param [:short, :paragraph] style The style of the text input.
    # @param [Integer, nil] min_length The minimum length of the text input.
    # @param [Integer, nil] max_length The maximum length of the text input.
    # @param [Boolean] required Whether the text input is required.
    # @param [String, nil] value The prefilled value of the text input.
    # @param [String, nil] placeholder The placeholder of the text input.
    #
    def initialize(label, custom_id, style, min_length: nil, max_length: nil, required: false, value: nil, placeholder: nil)
      @label = label
      @custom_id = custom_id
      @style = style
      @min_length = min_length
      @max_length = max_length
      @required = required
      @value = value
      @placeholder = placeholder
    end

    #
    # Converts the select menu to a hash.
    #
    # @see https://discord.com/developers/docs/interactions/message-components#text-inputs-text-input-structure Official Discord API docs
    # @return [Hash] A hash representation of the text input.
    #
    def to_hash
      {
        type: 4,
        label: @label,
        style: STYLES[@style],
        custom_id: @custom_id,
        min_length: @min_length,
        max_length: @max_length,
        required: @required,
        value: @value,
        placeholder: @placeholder,
      }
    end
  end
end
