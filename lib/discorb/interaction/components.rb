module Discorb

  #
  # Represents a message component interaction.
  # @abstract
  #
  class MessageComponentInteraction < Interaction
    include Interaction::SourceResponse
    include Interaction::UpdateResponse
    include Interaction::ModalResponse

    # @return [String] The content of the response.
    attr_reader :custom_id
    # @return [Discorb::Message] The target message.
    attr_reader :message

    @interaction_type = 3
    @interaction_name = :message_component

    # @private
    def initialize(client, data)
      super
      @message = Message.new(@client, data[:message].merge({ member: data[:member] }))
    end

    class << self
      # @private
      attr_reader :component_type

      # @private
      def make_interaction(client, data)
        nested_classes.each do |klass|
          return klass.new(client, data) if !klass.component_type.nil? && klass.component_type == data[:data][:component_type]
        end
        client.log.warn("Unknown component type #{data[:component_type]}, initialized Interaction")
        MessageComponentInteraction.new(client, data)
      end

      # @private
      def nested_classes
        constants.select { |c| const_get(c).is_a? Class }.map { |c| const_get(c) }
      end
    end

    #
    # Represents a button interaction.
    #
    class Button < MessageComponentInteraction
      @component_type = 2
      @event_name = :button_click
      # @return [String] The custom id of the button.
      attr_reader :custom_id

      private

      def _set_data(data)
        @custom_id = data[:custom_id]
      end
    end

    #
    # Represents a select menu interaction.
    #
    class SelectMenu < MessageComponentInteraction
      @component_type = 3
      @event_name = :select_menu_select
      # @return [String] The custom id of the select menu.
      attr_reader :custom_id
      # @return [Array<String>] The selected options.
      attr_reader :values

      # @!attribute [r] value
      #   @return [String] The first selected value.

      def value
        @values[0]
      end

      private

      def _set_data(data)
        @custom_id = data[:custom_id]
        @values = data[:values]
      end
    end
  end
end
