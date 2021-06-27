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

  class BadRequestError < HTTPError
    def initialize(resp, data)
      super
    end
  end

  class ForbiddenError < HTTPError
  end

  class NotFoundError < HTTPError
  end
end
