# frozen_string_literal: true

module Discorb
  #
  # Represents a modal interaction.
  #
  class ModalInteraction < Interaction
    include Interaction::SourceResponder

    @interaction_type = 5
    @interaction_name = :modal_submit
    @event_name = :modal_submit

    # @return [String] The custom id of the modal.
    attr_reader :custom_id
    # @return [{String => String}] The contents of the modal.
    attr_reader :contents

    private

    def _set_data(data)
      @custom_id = data[:custom_id]
      @contents =
        data[:components].to_h do |component|
          [
            component[:components][0][:custom_id],
            component[:components][0][:value]
          ]
        end
    end

    class << self
      alias make_interaction new
    end
  end
end
