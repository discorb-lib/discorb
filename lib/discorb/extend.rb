# frozen_string_literal: true

class Time
  def to_df(type = nil)
    if type.nil?
      "<t:#{to_i}>"
    else
      "<t:#{to_i}:#{type}>"
    end
  end
end
