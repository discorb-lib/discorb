# frozen_string_literal: true

module Discorb
  #
  # Represents a DM channel.
  #
  class DMChannel < Channel
    include Messageable

    #
    # Returns the channel id to request.
    # @private
    #
    # @return [Async::Task<Discorb::Snowflake>] A task that resolves to the channel id.
    #
    def channel_id
      Async { @id }
    end

    private

    def _set_data(data)
      @id = Snowflake.new(data)
    end
  end
end
