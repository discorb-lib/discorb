# frozen_string_literal: true

module Discorb
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

    class << self
      #
      # Creates a new text input from a hash.
      #
      # @param [Hash] data The hash to create the text input from.
      #
      # @return [Discorb::TextInput] The created text input.
      #
      def from_hash(data)
        new(
          data[:label],
          data[:custom_id],
          STYLES.key(data[:style]),
          min_length: data[:min_length],
          max_length: data[:max_length],
          required: data[:required],
          value: data[:value],
          placeholder: data[:placeholder],
        )
      end
    end
  end
end
