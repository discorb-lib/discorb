# frozen_string_literal: true

require "net/https"

module Discorb
  #
  # A class to handle http requests.
  # @private
  #
  class HTTP
    @nil_body = nil

    # @private
    def initialize(client)
      @client = client
      @ratelimit_handler = RatelimitHandler.new(client)
    end

    #
    # Execute a GET request.
    # @async
    #
    # @param [String] path The path to the resource.
    # @param [Hash] headers The headers to send with the request.
    # @param [String] audit_log_reason The audit log reason to send with the request.
    # @param [Hash] kwargs The keyword arguments.
    #
    # @return [Array(Net::HTTPResponse, Hash)] The response and as JSON.
    # @return [Async::Task<Array(Net::HTTPResponse, nil)>] The response was 204.
    #
    # @raise [Discorb::HTTPError] The request was failed.
    #
    def get(path, headers: nil, audit_log_reason: nil, **kwargs)
      Async do |task|
        @ratelimit_handler.wait("GET", path)
        resp = http.get(get_path(path), get_headers(headers, "", audit_log_reason), **kwargs)
        data = get_response_data(resp)
        @ratelimit_handler.save("GET", path, resp)
        handle_response(:patch, resp, data, path, nil, headers, audit_log_reason, kwargs)
      end
    end

    #
    # Execute a POST request.
    # @async
    #
    # @param [String] path The path to the resource.
    # @param [String, Hash] body The body of the request.
    # @param [Hash] headers The headers to send with the request.
    # @param [String] audit_log_reason The audit log reason to send with the request.
    # @param [Hash] kwargs The keyword arguments.
    #
    # @return [Array(Net::HTTPResponse, Hash)] The response and as JSON.
    # @return [Async::Task<Array(Net::HTTPResponse, nil)>] The response was 204.
    #
    # @raise [Discorb::HTTPError] The request was failed.
    #
    def post(path, body = "", headers: nil, audit_log_reason: nil, **kwargs)
      Async do |task|
        @ratelimit_handler.wait("POST", path)
        resp = http.post(get_path(path), get_body(body), get_headers(headers, body, audit_log_reason), **kwargs)
        data = get_response_data(resp)
        @ratelimit_handler.save("POST", path, resp)
        handle_response(:post, resp, data, path, body, headers, audit_log_reason, kwargs)
      end
    end

    #
    # Execute a multipart POST request.
    # @async
    #
    # @param [String] path The path to the resource.
    # @param [String, Hash] body The body of the request.
    # @param [Array<Discorb::File>] files The files to upload.
    # @param [Hash] headers The headers to send with the request.
    # @param [String] audit_log_reason The audit log reason to send with the request.
    # @param [Hash] kwargs The keyword arguments.
    #
    # @return [Array(Net::HTTPResponse, Hash)] The response and as JSON.
    # @return [Async::Task<Array(Net::HTTPResponse, nil)>] The response was 204.
    #
    # @raise [Discorb::HTTPError] The request was failed.
    #
    def multipart_post(path, body = "", files, headers: nil, audit_log_reason: nil, **kwargs)
      Async do |task|
        @ratelimit_handler.wait("POST", path)
        req = Net::HTTP::Post.new(get_path(path), get_headers(headers, body, audit_log_reason), **kwargs)
        data = [
          ["payload_json", get_body(body)],
        ]
        files&.each_with_index do |file, i|
          next if file.nil?
          data << [ "files[#{i}]", file.io, { filename: file.filename, content_type: file.content_type } ]
        end
        req.set_form(data, "multipart/form-data")
        session = Net::HTTP.new("discord.com", 443)
        session.use_ssl = true
        resp = session.request(req)
        data = get_response_data(resp)
        @ratelimit_handler.save("POST", path, resp)
        handle_response(:post, resp, data, path, body, headers, audit_log_reason, kwargs)
      end
    end

    #
    # Execute a PATCH request.
    # @async
    #
    # @param [String] path The path to the resource.
    # @param [String, Hash] body The body of the request.
    # @param [Hash] headers The headers to send with the request.
    # @param [String] audit_log_reason The audit log reason to send with the request.
    # @param [Hash] kwargs The keyword arguments.
    #
    # @return [Array(Net::HTTPResponse, Hash)] The response and as JSON.
    # @return [Async::Task<Array(Net::HTTPResponse, nil)>] The response was 204.
    #
    # @raise [Discorb::HTTPError] The request was failed.
    #
    def patch(path, body = "", headers: nil, audit_log_reason: nil, **kwargs)
      Async do |task|
        @ratelimit_handler.wait("PATCH", path)
        resp = http.patch(get_path(path), get_body(body), get_headers(headers, body, audit_log_reason), **kwargs)
        data = get_response_data(resp)
        @ratelimit_handler.save("PATCH", path, resp)
        handle_response(:patch, resp, data, path, body, headers, audit_log_reason, kwargs)
      end
    end

    #
    # Execute a PATCH request.
    # @async
    #
    # @param [String] path The path to the resource.
    # @param [String, Hash] body The body of the request.
    # @param [Hash] headers The headers to send with the request.
    # @param [String] audit_log_reason The audit log reason to send with the request.
    # @param [Hash] kwargs The keyword arguments.
    #
    # @return [Array(Net::HTTPResponse, Hash)] The response and as JSON.
    # @return [Async::Task<Array(Net::HTTPResponse, nil)>] The response was 204.
    #
    # @raise [Discorb::HTTPError] The request was failed.
    #
    def multipart_patch(path, body = "", headers: nil, audit_log_reason: nil, **kwargs)
      Async do |task|
        @ratelimit_handler.wait("PATCH", path)
        req = Net::HTTP::Patch.new(get_path(path), get_headers(headers, body, audit_log_reason), **kwargs)
        data = [
          ["payload_json", get_body(body)],
        ]
        files&.each_with_index do |file, i|
          data << [ "files[#{i}]", file.io, { filename: file.filename, content_type: file.content_type } ]
        end
        req.set_form(data, "multipart/form-data")
        session = Net::HTTP.new("discord.com", 443)
        session.use_ssl = true
        resp = session.request(req)
        data = get_response_data(resp)
        @ratelimit_handler.save("PATCH", path, resp)
        handle_response(:patch, resp, data, path, body, headers, audit_log_reason, kwargs)
      end
    end
    #
    # Execute a PUT request.
    # @async
    #
    # @param [String] path The path to the resource.
    # @param [String, Hash] body The body of the request.
    # @param [Hash] headers The headers to send with the request.
    # @param [String] audit_log_reason The audit log reason to send with the request.
    # @param [Hash] kwargs The keyword arguments.
    #
    # @return [Array(Net::HTTPResponse, Hash)] The response and as JSON.
    # @return [Async::Task<Array(Net::HTTPResponse, nil)>] The response was 204.
    #
    # @raise [Discorb::HTTPError] The request was failed.
    #
    def put(path, body = "", headers: nil, audit_log_reason: nil, **kwargs)
      Async do |task|
        @ratelimit_handler.wait("PUT", path)
        resp = http.put(get_path(path), get_body(body), get_headers(headers, body, audit_log_reason), **kwargs)
        data = get_response_data(resp)
        @ratelimit_handler.save("PUT", path, resp)
        handle_response(:put, resp, data, path, body, headers, audit_log_reason, kwargs)
      end
    end

    #
    # Execute a DELETE request.
    # @async
    #
    # @param [String] path The path to the resource.
    # @param [Hash] headers The headers to send with the request.
    # @param [String] audit_log_reason The audit log reason to send with the request.
    # @param [Hash] kwargs The keyword arguments.
    #
    # @return [Array(Net::HTTPResponse, Hash)] The response and as JSON.
    # @return [Async::Task<Array(Net::HTTPResponse, nil)>] The response was 204.
    #
    # @raise [Discorb::HTTPError] The request was failed.
    #
    def delete(path, headers: nil, audit_log_reason: nil, **kwargs)
      Async do
        @ratelimit_handler.wait("DELETE", path)
        resp = http.delete(get_path(path), get_headers(headers, "", audit_log_reason))
        data = get_response_data(resp)
        @ratelimit_handler.save("DELETE", path, resp)
        handle_response(:delete, resp, data, path, nil, headers, audit_log_reason, kwargs)
      end
    end

    def inspect
      "#<#{self.class} client=#{@client}>"
    end

    private

    def handle_response(method, resp, data, path, body, headers, audit_log_reason, kwargs)
      case resp.code
      when "429"
        @client.log.info("Rate limit exceeded for #{method} #{path}, waiting #{data[:retry_after]} seconds")
        sleep(data[:retry_after])
        if body
          __send__(method, path, body, headers: headers, audit_log_reason: audit_log_reason, **kwargs).wait
        else
          __send__(method, path, headers: headers, audit_log_reason: audit_log_reason, **kwargs).wait
        end
      when "400"
        raise BadRequestError.new(resp, data)
      when "401"
        raise UnauthorizedError.new(resp, data)
      when "403"
        raise ForbiddenError.new(resp, data)
      when "404"
        raise NotFoundError.new(resp, data)
      else
        [resp, data]
      end
    end

    def get_headers(headers, body = "", audit_log_reason = nil)
      ret = if body.nil? || body == ""
          { "User-Agent" => USER_AGENT, "authorization" => "Bot #{@client.token}" }
        else
          { "User-Agent" => USER_AGENT, "authorization" => "Bot #{@client.token}",
            "content-type" => "application/json" }
        end
      ret.merge!(headers) if !headers.nil? && headers.length.positive?
      ret["X-Audit-Log-Reason"] = audit_log_reason unless audit_log_reason.nil?
      ret
    end

    def get_body(body)
      if body.nil?
        ""
      elsif body.is_a?(String)
        body
      else
        recr_utf8(body).to_json
      end
    end

    def get_path(path)
      full_path = if path.start_with?("https://")
          path
        else
          API_BASE_URL + path
        end
      uri = URI(full_path)
      full_path.sub(uri.scheme + "://" + uri.host, "")
    end

    def get_response_data(resp)
      begin
        data = JSON.parse(resp.body, symbolize_names: true)
      rescue JSON::ParserError, TypeError
        if resp.body.nil? || resp.body.empty?
          data = nil
        else
          data = resp.body
        end
      end
      if resp["Via"].nil? && resp.code == "429" && data.is_a?(String)
        raise CloudFlareBanError.new(resp, @client)
      end
      data
    end

    def http
      https = Net::HTTP.new("discord.com", 443)
      https.use_ssl = true
      https
    end

    def recr_utf8(data)
      case data
      when Hash
        data.each do |k, v|
          data[k] = recr_utf8(v)
        end
        data
      when Array
        data.each_index do |i|
          data[i] = recr_utf8(data[i])
        end
        data
      when String
        data.dup.force_encoding(Encoding::UTF_8)
      else
        data
      end
    end
  end
end
