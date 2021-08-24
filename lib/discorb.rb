# frozen_string_literal: true

# A new wrapper for the Discorb API.
#
# @author sevenc-nanashi
module Discorb
  # @!visibility private
  # @!macro [new] async
  #   @note This is an asynchronous method, it will return a `Async::Task` object. Use `Async::Task#wait` to get the result.
  #
  # @!macro [new] client_cache
  #   @note This method returns an object from client cache. it will return `nil` if the object is not in cache.
  #   @return [nil] The object wasn't cached.
  #
  # @!macro members_intent
  #   @note This method requires `members` intent. {file:docs/Intents.md Learn more here}.
  #
  # @!macro presence_intent
  #   @note This method requires `presence` intent. {file:docs/Intents.md Learn more here}.
  #
  # @!macro edit
  #   @note The arguments of this method are defaultly set to `:unset`. Specify value to set the value, if not don't specify or specify `:unset`.
  #
  # @!macro http
  #   @note This method calls HTTP request.
  #   @raise [Discorb::HTTPError] HTTP request failed.
  #
  def macro
    # NOTE: this method is only for YARD.
    puts 'Wow, You found the easter egg!\n\n'
    red = "\e[31m"
    reset = "\e[m"
    puts <<~"EASTEREGG"
          | .               #{red}   |     #{reset}
        __|                 #{red}   |__   #{reset}
       /  | |  __   __  _   #{red} _ |  \\  #{reset}
      (   | | (__  /   / \\ #{red}|/  |   ) #{reset}
       \\__| |  __) \\__ \\_/ #{red}|   |__/  #{reset}

            https://github.com/discorb-lib/discorb
    EASTEREGG
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
