# description: Run a client.
require "optparse"
require "json"
require "discorb/utils/colored_puts"
require "io/console"

ARGV.delete_at 0
# @!visibility private
LOG_LEVELS = %w[none debug info warn error fatal]

opt = OptionParser.new <<~BANNER
                         This command will run a client.

                         Usage: discorb run [options] [script]

                                   script                     The script to run. Defaults to 'main.rb'.
                       BANNER
options = {
  title: nil,
  log_level: nil,
  log_file: nil,
  log_color: nil,
  setup: nil,
  token: false,
}
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
opt.on("-s", "--setup", "Whether to setup application commands.") { |v| options[:setup] = v }
opt.on("-e", "--env [ENV]", "The name of the environment variable to use for token, or just `-e` or `--env` for intractive prompt.") { |v| options[:token] = v }
opt.on("-t", "--title TITLE", "The title of process.") { |v| options[:title] = v }
opt.parse!(ARGV)

script = ARGV[0]

script ||= "main.rb"

ENV["DISCORB_CLI_FLAG"] = "run"
ENV["DISCORB_CLI_OPTIONS"] = JSON.generate(options)

if options[:token]
  ENV["DISCORB_CLI_TOKEN"] = ENV[options[:token]]
  raise "#{options[:token]} is not set." if ENV["DISCORB_CLI_TOKEN"].nil?
elsif options[:token].nil? || options[:token] == "-"
  print "\e[90mPlease enter your token: \e[m"
  ENV["DISCORB_CLI_TOKEN"] = $stdin.noecho(&:gets).chomp
  puts ""
end

ENV["DISCORB_CLI_TITLE"] = options[:title]

begin
  load script
rescue LoadError
  eputs "Could not load script: \e[31m#{script}\e[91m"
end
