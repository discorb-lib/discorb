# frozen_string_literal: true

module Discorb
  # @private
  class Logger
    attr_accessor :out, :colorize_log

    LEVELS = %i[debug info warn error fatal].freeze

    def initialize(out, colorize_log, level)
      @out = out
      @level = LEVELS.index(level)
      @colorize_log = colorize_log
    end

    def inspect
      "#<#{self.class} level=#{level}>"
    end

    def level
      LEVELS[@level]
    end

    def level=(level)
      @level = LEVELS.index(level)
      raise ArgumentError, "Invalid log level: #{level}" unless @level
    end

    def debug(message, fallback: nil)
      return unless @level <= 0

      write_output("DEBUG", "\e[90m", message, fallback)
    end

    def info(message, fallback: nil)
      return unless @level <= 1

      write_output("INFO", "\e[94m", message, fallback)
    end

    def warn(message, fallback: nil)
      return unless @level <= 2

      write_output("WARN", "\e[93m", message, fallback)
    end

    def error(message, fallback: nil)
      return unless @level <= 3

      write_output("ERROR", "\e[31m", message, fallback)
    end

    def fatal(message, fallback: nil)
      return unless @level <= 4

      write_output("FATAL", "\e[91m", message, fallback)
    end

    class << self
      attr_reader :levels
    end

    private

    def write_output(name, color, message, fallback)
      unless @out
        fallback&.puts(message)

        return
      end

      time = Time.now.iso8601
      if @colorize_log
        @out.write("\e[90m#{time}\e[0m #{color}#{name.ljust(5)}\e[0m #{message}\n")
      else
        @out.write("#{time} #{name.ljust(5)} #{message}\n")
      end
      @out.flush
    end
  end
end
