# frozen_string_literal: true

# A new wrapper for the Discorb API.
#
# @author sevenc-nanashi
module Discorb
  # @!visibility private
  # @!macro [new] async
  #  @note This is an asynchronous method, it will return a +Async::Task+ object.
  #
  # @!macro [new] client_cache
  #  @note This method returns an object from client cache. it will return +nil+ if the object is not in cache.
  #  @return [nil] The object wasn't cached.
  #
  def macro
    # NOTE: this method is only for YARD.
  end
end
require_order = %w[common flag dictionary error internet intents emoji_table modules] +
                %w[user member guild emoji channel embed message] +
                %w[application audit_logs color components event extension] +
                %w[file guild_template image integration interaction invite log permission] +
                %w[presence reaction role sticker utils voice_state webhook] +
                %w[gateway_requests gateway] +
                %w[asset client extend]
require_order.each do |name|
  require_relative "discorb/#{name}.rb"
end
