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
        name = data[:name]
        options = nil
        if (option = data[:options]&.first)
          case option[:type]
          when 1
            name += " #{option[:name]}"
            options = option[:options]
          when 2
            name += " #{option[:name]}"
            if (option_sub = option[:options]&.first)
              if option_sub[:type] == 1
                name += " #{option_sub[:name]}"
                options = option_sub[:options]
              else
                options = option[:options]
              end
            end
          else
            options = data[:options]
          end
        end

        unless (command = @client.bottom_commands.find { |c| c.to_s == name && c.type_raw == 1 })
          @client.log.warn "Unknown command name #{name}, ignoring"
          next
        end

        option_map = command.options.map { |k, v| [k.to_s, v[:default]] }.to_h
        options ||= []
        options.each_with_index do |option|
          val = case option[:type]
            when 3, 4, 5, 10
              option[:value]
            when 6
              guild.members[option[:value]] || guild.fetch_member(option[:value]).wait
            when 7
              guild.channels[option[:value]] || guild.fetch_channels.wait.find { |channel| channel.id == option[:value] }
            when 8
              guild.roles[option[:value]] || guild.fetch_roles.wait.find { |role| role.id == option[:value] }
            when 9
              guild.members[option[:value]] || guild.roles[option[:value]] || guild.fetch_member(option[:value]).wait || guild.fetch_roles.wait.find { |role| role.id == option[:value] }
            end
          option_map[option[:name]] = val
        end
        focused_index = options.find_index { |o| o[:focused] }
        val = command.options.values[focused_index][:autocomplete]&.call(self, *command.options.map { |k, v| option_map[k.to_s] })
        send_complete_result(val)
      end
    end

    # @private
    def send_complete_result(val)
      @client.http.post("/interactions/#{@id}/#{@token}/callback", {
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
