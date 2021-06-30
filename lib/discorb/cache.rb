# frozen_string_literal: true

module Discorb
  class Cache
    def initialize
      @cache = {}
    end

    def register(id, body)
      @cache[id.to_i] = body
    end

    def get(id)
      @cache[id.to_i]
    end

    def values
      @cache.values
    end

    alias [] get
    alias []= register
  end
end
