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
          Button
        when 3
          SelectMenu
        when 4
          TextInput
        end.from_hash(data)
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
end

%w[button text_input select_menu].each do |name|
  require_relative "components/#{name}"
end
