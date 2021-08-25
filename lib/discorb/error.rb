# frozen_string_literal: true

module Discorb
  #
  # Error class for Discorb.
  # @abstract
  #
  class DiscorbError < StandardError
    private

    def enumerate_errors(hash)
      res = {}
      _recr_items([], hash, res)
      res
    end

    def _recr_items(key, item, res)
      case item
      when Array
        item.each_with_index do |v, i|
          _recr_items (key + [i]), v, res
        end
      when Hash
        item.each do |k, v|
          _recr_items (key + [k]), v, res
        end
      else
        res[key.join(".").gsub("_errors.", "")] = item
      end
    end
  end

  #
  # Represents a HTTP error.
  #
  class HTTPError < DiscorbError
    # @return [String] the HTTP response code.
    attr_reader :code
    # @return [Net::HTTPResponse] the HTTP response.
    attr_reader :response

    # @!visibility private
    def initialize(resp, data)
      @code = data[:code]
      @response = resp
      super(data[:message])
    end
  end

  #
  # Represents a 400 error.
  #
  class BadRequestError < HTTPError
    # @!visibility private
    def initialize(resp, data)
      @code = data[:code]
      @response = resp
      DiscorbError.instance_method(:initialize).bind(self).call(
        [data[:message], "\n", enumerate_errors(data[:errors]).map do |ek, ev|
          "#{ek}=>#{ev}"
        end.join("\n")].join("\n")
      )
    end
  end

  #
  # Represents a 403 error.
  #
  class ForbiddenError < HTTPError
  end

  #
  # Represents a 404 error.
  #
  class NotFoundError < HTTPError
  end

  #
  # Represents a error in client-side.
  #
  class ClientError < DiscorbError
  end

  #
  # Represents a timeout error.
  #
  class TimeoutError < DiscorbError
  end

  #
  # Represents a warning.
  #
  class NotSupportedWarning < DiscorbError
    def initialize(message)
      super("#{message} is not supported yet.")
    end
  end
end
