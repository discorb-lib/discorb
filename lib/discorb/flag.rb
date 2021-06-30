# frozen_string_literal: true

module Discorb
  class Flag
    attr_reader :values, :value

    @bits = {}

    def initialize(value)
      @value = value
      @values = {}
      self.class.bits.each_with_index do |(bn, bv), _i|
        @values[bn] = value & (1 << bv) != 0
      end
    end

    def method_missing(name, args = nil)
      if @values.key?(name.to_s.delete_suffix('?').to_sym)
        @values[name.to_s.delete_suffix('?').to_sym]
      else
        super
      end
    end

    def respond_to_missing?(sym, include_private)
      @values.key?(name.to_s.delete_suffix('?').to_sym) ? true : super
    end

    class << self
      attr_reader :bits
    end
  end
end
