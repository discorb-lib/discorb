# frozen_string_literal: true

module Discorb
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

    class << self
      #
      # Creates a new select menu from a hash.
      #
      # @param [Hash] data The hash to create the select menu from.
      #
      # @return [Discorb::SelectMenu] The created select menu.
      #
      def from_hash(data)
        new(
          data[:custom_id],
          data[:options].map { |o| SelectMenu::Option.from_hash(o) },
          placeholder: data[:placeholder],
          min_values: data[:min_values],
          max_values: data[:max_values],
        )
      end
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
          emoji: @emoji&.to_hash,
          default: @default,
        }
      end

      def inspect
        "#<#{self.class} #{@label}: #{@value}>"
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
  end
end
