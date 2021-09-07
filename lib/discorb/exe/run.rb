# description: Run a client.
require "optparse"
require "json"
require "discorb/utils/colored_puts"

ARGV.delete_at 0
LOG_LEVELS = %w[none debug info warn error fatal]

opt = OptionParser.new <<~BANNER
                         This command will run a client.

                         Usage: discorb run [options] [script]

                                   script                     The script to run.
                       BANNER
options = {
  deamon: false,
  log_level: nil,
  log_file: nil,
  log_color: nil,
}
opt.on("-d", "--deamon", "Run as a daemon.") { |v| options[:daemon] = v }
opt.on("-l", "--log-level LEVEL", "Log level.") do |v|
  unless LOG_LEVELS.include? v.downcase
    eputs "Invalid log level: \e[31m#{v}\e[91m"
    eputs "Valid log levels: \e[31m#{LOG_LEVELS.join("\e[91m, \e[31m")}\e[91m"
    exit 1
  end
  options[:log_level] = v.downcase
end
opt.on("-f", "--log-file FILE", "File to write log to.") { |v| options[:log_file] = v }
opt.on("-c", "--[no-]log-color", "Whether to colorize log output.") { |v| options[:log_color] = v }
opt.parse!(ARGV)

script = ARGV[0]
ENV["DISCORB_CLI_FLAG"] = "run"
ENV["DISCORB_CLI_OPTIONS"] = JSON.generate(options)

begin
  load script
rescue LoadError
  eputs "Could not load script: \e[31m#{script}\e[91m"
end
