# frozen_string_literal: true

module Discorb
  # @private
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
