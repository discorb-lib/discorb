# frozen_string_literal: true

module Discorb
  #
  # Represents auto complete interaction.
  #
  class AutoComplete < Interaction
    @interaction_type = 4
    @interaction_name = :auto_complete

    private

    def _set_data(data)
      super
      Sync do
        name, options =
          Discorb::CommandInteraction::ChatInputCommand.get_command_data(data)

        unless (
                 command =
                   @client.callable_commands.find do |c|
                     c.to_s == name && c.type_raw == 1
                   end
               )
          @client.logger.warn "Unknown command name #{name}, ignoring"
          next
        end

        option_map = command.options.to_h { |k, v| [k.to_s, v[:default]] }
        Discorb::CommandInteraction::ChatInputCommand.modify_option_map(
          option_map,
          options,
          guild,
          {},
          {}
        )
        focused_index = options.find_index { |o| o[:focused] }
        val =
          command.options.values.filter do |option|
            option[:type] != :attachment
          end[
            focused_index
          ][
            :autocomplete
          ]&.call(self, *command.options.map { |k, _v| option_map[k.to_s] })
        send_complete_result(val)
      end
    end

    def send_complete_result(val)
      @client
        .http
        .request(
          Route.new(
            "/interactions/#{@id}/#{@token}/callback",
            "//interactions/:interaction_id/:token/callback",
            :post
          ),
          {
            type: 8,
            data: {
              choices: val.map { |vk, vv| { name: vk, value: vv } }
            }
          }
        )
        .wait
    rescue Discorb::NotFoundError
      @client.logger.warn "Failed to send auto complete result, " \
                            "This may be caused by the suggestion is taking too long (over 3 seconds) to respond"
    end

    class << self
      alias make_interaction new
    end
  end
end
