# frozen_string_literal: true

module Discorb
  class Dictionary
    attr_accessor :limit

    def initialize(hash = {}, limit: nil)
      @cache = hash.transform_keys(&:to_s)
      @limit = limit
    end

    def register(id, body)
      @cache[id.to_s] = body
      @cache = @cache.sort_by { |_, v| v.position }.to_h if body.respond_to?(:position)
      @cache.delete(@cache.values[-1]) if @cache.size > @limit
      body
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
