# frozen_string_literal: true

module Discorb
  # @!visibility private
  module Utils
    def try(object, message, ...)
      if object.respond_to?(message)
        object.send(message, ...)
      else
        object
      end
    end

    module_function :try
  end
end

class Async::Node	
  def description
    @object_name ||= "#{self.class}:0x#{object_id.to_s(16)}#{@transient ? ' transient' : nil}"

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