# frozen_string_literal: true

module Discorb
  # @!visibility private
  class Logger
    attr_reader :out, :colorize_log

    @levels = %i[debug info warn error fatal].freeze

    def initialize(out, colorize_log, level)
      @out = out
      @level = self.class.levels.index(level)
      @colorize_log = colorize_log
    end

    def level
      @levels[@level]
    end

    def level=(level)
      @level = @levels.index(level)
    end

    def debug(message)
      return unless @level <= 0

      write_output("DEBUG", "\e[90m", message)
    end

    def info(message)
      return unless @level <= 1

      write_output("INFO", "\e[94m", message)
    end

    def warn(message)
      return unless @level <= 2

      write_output("WARN", "\e[93m", message)
    end

    def error(message)
      return unless @level <= 3

      write_output("ERROR", "\e[31m", message)
    end

    def fatal(message)
      return unless @level <= 4

      write_output("FATAL", "\e[91m", message)
    end

    class << self
      attr_reader :levels
    end

    private

    def write_output(name, color, message)
      return unless @out

      if @colorize_log
        @out.puts("[#{Time.now.iso8601}] #{color}#{name}\e[m -- #{message}")
      else
        @out.puts("[#{Time.now.iso8601}] #{name} -- #{message}")
      end
    end
  end
end
