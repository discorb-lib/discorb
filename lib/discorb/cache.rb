# frozen_string_literal: true

module Discorb
  class Cache
    def initialize
      @cache = {}
    end

    def register(id, body)
      @cache[id.to_s] = body
    end

    def delete(id)
      @cache.delete(id.to_s)
    end

    def get(id)
      res = @cache[id.to_s]
      if res.nil?
        begin
          @cache.values[id.to_i]
        rescue RangeError
          nil
        end
      else
        res
      end
    end

    def values
      @cache.values
    end

    alias [] get
    alias []= register
  end
end
