# frozen_string_literal: true

# rubocop: disable Style/Documentation

class Time
  #
  # Format a time object to a Discord formatted string.
  #
  # @param ["f", "F", "d", "D", "t", "T", "R"] type The format to use.
  #
  # @return [String] The formatted time.
  #
  def to_df(type = nil)
    type.nil? ? "<t:#{to_i}>" : "<t:#{to_i}:#{type}>"
  end
end

# @private
module Async
  class Node
    alias inspect to_s
  end
end

# rubocop: enable Style/Documentation
