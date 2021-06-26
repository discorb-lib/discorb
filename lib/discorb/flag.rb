module Discorb
  class Flag
    attr_reader :values, :value
    @bits = {}

    def initialize(value)
      @value = value
      @values = {}
      self.class.bits.each_with_index do |(bn, bv), i|
        @values[bn] = value & (1 << bv) != 0
      end
    end

    def method_missing(name, args = nil)
      if @values.key?(name)
        @values[name]
      else
        super
      end
    end

    def respond_to_missing?(sym, include_private)
      @values.key?(name) ? true : super
    end

    private

    def self.bits
      @bits
    end
  end
end
