# frozen_string_literal: true

# description: Run a client.
require "optparse"
require "json"
require "discorb/utils/colored_puts"
require "io/console"
require "discorb"

opt = OptionParser.new <<~BANNER
                         This command will run a client.

                         Usage: discorb run [options] [script]

                                   script                     The script to run. Defaults to 'main.rb'.
                       BANNER
options = { title: nil, setup: nil, token: false }
opt.on("-s", "--setup", "Whether to setup application commands.") do |v|
  options[:setup] = v
end
opt.on(
  "-e",
  "--env [ENV]",
  "The name of the environment variable to use for token, or just `-e` or `--env` for intractive prompt."
) { |v| options[:token] = v }
opt.on("-t", "--title TITLE", "The title of process.") do |v|
  options[:title] = v
end
opt.parse!(ARGV)

script = ARGV[0]

if script.nil?
  script = "main.rb"
  dir = Dir.pwd
  loop do
    if File.exist?(File.join(dir, "main.rb"))
      script = File.join(dir, "main.rb")
      break
    end
    break if dir == File.dirname(dir)

    dir = File.dirname(dir)
  end
  if File.dirname(script) != Dir.pwd
    Dir.chdir(File.dirname(script))
    iputs "Changed directory to \e[m#{File.dirname(script)}"
  end
end

ENV["DISCORB_CLI_FLAG"] = "run"
ENV["DISCORB_CLI_OPTIONS"] = JSON.generate(options)

if options[:token]
  ENV["DISCORB_CLI_TOKEN"] = ENV.fetch(options[:token], nil)
  raise "#{options[:token]} is not set." if ENV["DISCORB_CLI_TOKEN"].nil?
elsif options[:token].nil? || options[:token] == "-"
  print "\e[90mPlease enter your token: \e[m"
  ENV["DISCORB_CLI_TOKEN"] = $stdin.noecho(&:gets).chomp
  puts ""
end

ENV["DISCORB_CLI_TITLE"] = options[:title]

if File.exist? script
  exec "ruby #{script}"
else
  eputs "Could not load script: \e[31m#{script}\e[91m"
end
