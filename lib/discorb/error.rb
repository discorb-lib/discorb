# frozen_string_literal: true

require 'yaml'

module Discorb
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
        res[key.join('.').gsub('_errors.', '')] = item
      end
    end
  end

  class HTTPError < DiscorbError
    def initialize(resp, data)
      @code = data[:code]
      @response = resp
      super(data[:message])
    end
  end

  class BadRequestError < DiscorbError
    def initialize(resp, data)
      @code = data[:code]
      @response = resp
      super([data[:message], "\n", enumerate_errors(data[:errors]).map do |ek, ev|
                                     "#{ek}=>#{ev}"
                                   end.join("\n")].join("\n"))
    end
  end

  class ForbiddenError < HTTPError
  end

  class NotFoundError < HTTPError
  end

  class ClientError < DiscorbError
  end

  class NotSupportedWarning < DiscorbError
    def initialize(message)
      super("#{message} is not supported yet.")
    end
  end
end
