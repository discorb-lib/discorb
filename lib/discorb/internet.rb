require "async/http/internet"
require_relative "common"
require_relative "error"

module Discorb
  class Internet < Async::HTTP::Internet
    def initialize(client)
      @client = client
      super()
    end

    def get(path, **kwargs)
      Async do |task|
        resp = super(API_BASE_URL + path, { "User-Agent" => USER_AGENT, "authorization" => "Bot " + @client.token }, **kwargs)
        data = JSON.parse(resp.read, symbolize_names: true)
        test_error(if resp.status == "429"
          task.sleep(data[:retry_after])
          get(path, **kwargs)
        else
          [resp, data]
        end)
      end
    end

    def post(path, body, **kwargs)
      Async do |task|
        resp = super(API_BASE_URL + path, body.to_json, { "User-Agent" => USER_AGENT, "authorization" => "Bot " + @client.token }, **kwargs)
        data = JSON.parse(resp.read, symbolize_names: true)
        test_error(if resp.status == "429"
          task.sleep(data[:retry_after])
          post(path, **kwargs)
        else
          [resp, data]
        end)
      end
    end

    def patch(path, body, **kwargs)
      Async do |task|
        resp = super(API_BASE_URL + path, body.to_json, { "User-Agent" => USER_AGENT, "authorization" => "Bot " + @client.token }, **kwargs)
        data = JSON.parse(resp.read, symbolize_names: true)
        test_error(if resp.status == "429"
          task.sleep(data[:retry_after])
          patch(path, **kwargs)
        else
          [resp, data]
        end)
      end
    end

    def put(path, body, **kwargs)
      Async do |task|
        resp = super(API_BASE_URL + path, body.to_json, { "User-Agent" => USER_AGENT, "authorization" => "Bot " + @client.token }, **kwargs)
        data = JSON.parse(resp.read, symbolize_names: true)
        test_error(if resp.status == "429"
          task.sleep(data[:retry_after])
          put(path, **kwargs)
        else
          [resp, data]
        end)
      end
    end

    def delete(path, body, **kwargs)
      Async do |task|
        resp = super(API_BASE_URL + path, body.to_json, { "User-Agent" => USER_AGENT, "authorization" => "Bot " + @client.token }, **kwargs)
        data = JSON.parse(resp.read, symbolize_names: true)
        test_error(if resp.status == "429"
          task.sleep(data[:retry_after])
          delete(path, **kwargs)
        else
          [resp, data]
        end)
      end
    end

    def inspect
      return "#<Discorb::Internet:0x#{self.object_id.to_s(16)}>"
    end

    private

    def test_error(ary)
      resp, data = *ary
      case resp.status
      when 400
        raise BadRequestError.new(resp, data)
      when 403
        raise ForbiddenError.new(resp, data)
      when 404
        raise NotFoundError.new(resp, data)
      else
        return [resp, data]
      end
    end
  end
end
