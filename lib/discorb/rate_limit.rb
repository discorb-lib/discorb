# frozen_string_literal: true

module Discorb
  #
  # Class to handle rate limiting.
  #
  class RatelimitHandler
    def initialize(client)
      @client = client
      @ratelimit_hash = {}
      @path_ratelimit_hash = {}
    end

    def wait(method, path)
      return if path.start_with?("https://")

      return unless hash = @path_ratelimit_hash[method + path]

      return unless b = @ratelimit_hash[hash]

      if b[:reset_at] < Time.now.to_i
        @ratelimit_hash.delete(hash)
        return
      end
      return if b[:remaining] > 0

      @client.log.info("Ratelimit reached, waiting for #{b[:reset_at] - Time.now.to_i} seconds")
      sleep(b[:reset_at] - Time.now.to_i)
    end

    def save(method, path, resp)
      return unless resp["X-RateLimit-Remaining"]

      @path_ratelimit_hash[method + path] = resp["X-RateLimit-Bucket"]
      @ratelimit_hash[resp["X-RateLimit-Bucket"]] = {
        remaining: resp["X-RateLimit-Remaining"].to_i,
        reset_at: resp["X-RateLimit-Reset"].to_i,
      }
    end
  end
end
