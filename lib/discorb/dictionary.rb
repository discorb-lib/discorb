# frozen_string_literal: true

module Discorb
  class Dictionary
    attr_accessor :limit

    def initialize(hash = {}, limit: nil, sort: false)
      @cache = hash.transform_keys(&:to_s)
      @limit = limit
      @sort = sort
    end

    def register(id, body)
      @cache[id.to_s] = body
      @cache = @cache.sort_by(&@sort).to_h if @sort
      @cache.remove(@cache.values[-1]) if !@limit.nil? && @cache.size > @limit
      body
    end

    def remove(id)
      @cache.remove(id.to_s)
    end

    def get(id)
      res = @cache[id.to_s]
      if res.nil? && id.is_a?(Integer) && id < @cache.length
        @cache.values[id]
      else
        res
      end
    end

    def values
      @cache.values
    end

    def has?(id)
      !self[id].nil?
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
