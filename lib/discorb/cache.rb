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
      return @cache.values
    end

    alias_method :[], :get
    alias_method :[]=, :register
  end
end
