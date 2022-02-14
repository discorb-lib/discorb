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
    if type.nil?
      "<t:#{to_i}>"
    else
      "<t:#{to_i}:#{type}>"
    end
  end
end

# @private
module Async
  class Node
    def description
      @object_name ||= "#{self.class}:0x#{object_id.to_s(16)}#{@transient ? " transient" : nil}"

      if @annotation
        "#{@object_name} #{@annotation}"
      elsif line = self.backtrace(0, 1)&.first
        "#{@object_name} #{line}"
      else
        @object_name
      end
    end

    def to_s
      "\#<#{self.description}>"
    end

    alias inspect to_s
  end
end

# rubocop: enable Style/Documentation
