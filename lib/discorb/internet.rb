# frozen_string_literal: true

require 'async/http/internet'
require_relative 'common'
require_relative 'error'

module Discorb
  class Internet < Async::HTTP::Internet
    @nil_body = nil

    def initialize(client)
      @client = client
      super()
    end

    def get(path, headers: nil, audit_log_reason: nil, **kwargs)
      Async do |task|
        resp = super(API_BASE_URL + path, get_headers(headers, audit_log_reason), **kwargs)
        rd = resp.read
        data = if rd.nil?
                 nil
               else
                 JSON.parse(rd, symbolize_names: true)
               end
        test_error(if resp.status == '429'
                     @client.log.warn "Ratelimit exceeded for #{path}, trying again in #{data[:retry_after]} seconds."
                     task.sleep(data[:retry_after])
                     get(path, **kwargs)
                   else
                     [resp, data]
                   end)
      end
    end

    def post(path, body, headers: nil, audit_log_reason: nil, **kwargs)
      Async do |task|
        resp = super(API_BASE_URL + path, get_headers(headers, body, audit_log_reason), get_body(body), **kwargs)
        rd = resp.read
        data = if rd.nil?
                 nil
               else
                 JSON.parse(rd, symbolize_names: true)
               end
        test_error(if resp.status == '429'
                     task.sleep(data[:retry_after])
                     post(path, **kwargs)
                   else
                     [resp, data]
                   end)
      end
    end

    def patch(path, body, headers: nil, audit_log_reason: nil, **kwargs)
      Async do |task|
        resp = super(API_BASE_URL + path, get_headers(headers, body, audit_log_reason), get_body(body), **kwargs)
        rd = resp.read
        data = if rd.nil?
                 nil
               else
                 JSON.parse(rd, symbolize_names: true)
               end
        test_error(if resp.status == '429'
                     task.sleep(data[:retry_after])
                     patch(path, **kwargs)
                   else
                     [resp, data]
                   end)
      end
    end

    def put(path, body, headers: nil, audit_log_reason: nil, **kwargs)
      Async do |task|
        resp = super(API_BASE_URL + path, get_headers(headers, body, audit_log_reason), get_body(body), **kwargs)
        rd = resp.read
        data = if rd.nil?
                 nil
               else
                 JSON.parse(rd, symbolize_names: true)
               end
        test_error(if resp.status == '429'
                     task.sleep(data[:retry_after])
                     put(path, **kwargs)
                   else
                     [resp, data]
                   end)
      end
    end

    def delete(path, body, headers: nil, audit_log_reason: nil, **kwargs)
      Async do |task|
        resp = super(API_BASE_URL + path, get_headers(headers, body, audit_log_reason), get_body(body), **kwargs)
        rd = resp.read
        data = if rd.nil?
                 nil
               else
                 JSON.parse(rd, symbolize_names: true)
               end
        test_error(if resp.status == '429'
                     task.sleep(data[:retry_after])
                     delete(path, **kwargs)
                   else
                     [resp, data]
                   end)
      end
    end

    def inspect
      "#<#{self.class} client=#{@client}>"
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
        [resp, data]
      end
    end

    def get_headers(headers, body = nil, audit_log_reason = nil)
      ret = if body.nil?
              { 'User-Agent' => USER_AGENT, 'authorization' => "Bot #{@client.token}" }
            else
              { 'User-Agent' => USER_AGENT, 'authorization' => "Bot #{@client.token}",
                'content-type' => 'application/json' }
            end
      ret.merge(headers) if !headers.nil? && headers.length.positive?
      ret['X-Audit-Log-Reason'] = audit_log_reason unless audit_log_reason.nil?
      ret
    end

    def get_body(body)
      if body.nil?
        []
      elsif body.is_a?(String)
        [body]
      else
        [body.to_json]
      end
    end
  end
end
