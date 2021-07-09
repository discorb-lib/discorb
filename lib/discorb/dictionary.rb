# frozen_string_literal: true

module Discorb
  class Dictionary
    def initialize(hash = {})
      @cache = hash
    end

    def register(id, body)
      @cache[id.to_s] = body
    end

    def delete(id)
      @cache.delete(id.to_s)
    end

    def get(id)
      if @cache.length <= id.to_i
        return id.is_a?(Integer) ? @cache.values[id] : @cache[id.to_s]
      end

      res = @cache[id.to_s]
      if res.nil?
        @cache.values[id.to_i]
      else
        res
      end
    end

    def values
      @cache.values
    end

    def has?(id)
      @cache.key?(id.to_s)
    end

    def method_missing(name, args = [], kwargs = {}, &block)
      if values.respond_to?(name)
        values.send(name, *args, **kwargs, &block)
      else
        super
      end
    end

    def respond_to_missing?(name, args, kwargs)
      if values.respond_to?(name)
        true
      else
        super
      end
    end
    alias [] get
    alias []= register
  end
end
