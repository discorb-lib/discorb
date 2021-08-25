# frozen_string_literal: true

class Time
  #
  # Format a time object to a Discord formatted string.
  #
  # @param ["f", "F", "d", "D", "t", "T", "R"] format The format to use.
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
