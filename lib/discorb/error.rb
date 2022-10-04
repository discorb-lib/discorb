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
      res = {} if res == { "" => nil }
      res
    end

    def _recr_items(key, item, res)
      case item
      when Array
        item.each_with_index { |v, i| _recr_items (key + [i]), v, res }
      when Hash
        item.each { |k, v| _recr_items (key + [k]), v, res }
      else
        res[key.join(".").gsub("_errors.", "")] = item
      end
    end
  end

  #
  # Represents a HTTP error.
  # @abstract
  #
  class HTTPError < DiscorbError
    # @return [String] the JSON response code.
    # @see https://discord.com/developers/docs/topics/opcodes-and-status-codes#json-json-error-codes
    attr_reader :code
    # @return [Net::HTTPResponse] the HTTP response.
    attr_reader :response

    #
    # Initialize a new instance of the HTTPError class.
    # @private
    #
    def initialize(resp, data)
      @code = data[:code]
      @response = resp
      super(data[:message] + " (#{@code})")
    end
  end

  #
  # Represents a 400 error.
  #
  class BadRequestError < HTTPError
    #
    # Initialize a new instance of the BadRequestError class.
    # @private
    #
    def initialize(resp, data)
      @code = data[:code]
      @response = resp
      DiscorbError
        .instance_method(:initialize)
        .bind(self)
        .call(
          [
            data[:message] + " (#{@code})",
            enumerate_errors(data[:errors])
              .map { |ek, ev| "#{ek}=>#{ev}" }
              .join("\n")
          ].join("\n")
        )
    end
  end

  #
  # Represents a 401 error.
  #
  class UnauthorizedError < HTTPError
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
  # Represents a error because of a cloudflare ban.
  #
  class CloudFlareBanError < HTTPError
    def initialize(_resp, client)
      @client = client
      @client.close
      message = <<~MESSAGE
        The client is banned from CloudFlare.
        Hint: Try to decrease the number of requests per second, e.g. Use sleep in between requests.
      MESSAGE
      warn message
      DiscorbError.instance_method(:initialize).bind(self).call(message)
    end
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
