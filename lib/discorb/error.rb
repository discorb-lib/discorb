require "yaml"

module Discorb
  class DiscorbError < StandardError
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
      super(data[:message] + "\n" + YAML.dump(data[:errors]))
    end
  end

  class ForbiddenError < HTTPError
  end

  class NotFoundError < HTTPError
  end

  class ClientError < DiscorbError
  end
end
