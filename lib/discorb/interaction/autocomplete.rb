# frozen_string_literal: true
module Discorb
  #
  # Represents auto complete interaction.
  #
  class AutoComplete < Interaction
    @interaction_type = 4
    @interaction_name = :auto_complete

    # @private
    def _set_data(data)
      super
      Sync do
        name, options = Discorb::CommandInteraction::SlashCommand.get_command_data(data)

        unless (command = @client.bottom_commands.find { |c| c.to_s == name && c.type_raw == 1 })
          @client.log.warn "Unknown command name #{name}, ignoring"
          next
        end

        option_map = command.options.to_h { |k, v| [k.to_s, v[:default]] }
        Discorb::CommandInteraction::SlashCommand.modify_option_map(option_map, options, guild, {}, {})
        focused_index = options.find_index { |o| o[:focused] }
        val = command.options.values.filter { |option| option[:type] != :attachment }[focused_index][:autocomplete]&.call(self, *command.options.map { |k, _v| option_map[k.to_s] })
        send_complete_result(val)
      end
    end

    # @private
    def send_complete_result(val)
      @client.http.request(Route.new("/interactions/#{@id}/#{@token}/callback", "//interactions/:interaction_id/:token/callback", :post), {
        type: 8,
        data: {
          choices: val.map do |vk, vv|
            {
              name: vk,
              value: vv,
            }
          end,
        },
      }).wait
    rescue Discorb::NotFoundError
      @client.log.warn "Failed to send auto complete result, This may be caused by the suggestion is taking too long (over 3 seconds) to respond", fallback: $stderr
    end

    class << self
      alias make_interaction new
    end
  end
end
