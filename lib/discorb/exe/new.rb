# frozen_string_literal: true

# description: Make files for the discorb project.

require "optparse"
require "discorb"
require "pathname"
require_relative "../utils/colored_puts"

$path = Dir.pwd

# @private
FILES = {
  "main.rb" => <<~'RUBY',
    # frozen_string_literal: true

    require "discorb"
    require "dotenv/load"  # Load environment variables from .env file.

    client = Discorb::Client.new  # Create client for connecting to Discord

    client.once :standby do
      puts "Logged in as #{client.user}"  # Prints username of logged in user
    end

    client.run ENV["%<token>s"]  # Starts client
  RUBY
  "main.rb_nc" => <<~'RUBY',
    # frozen_string_literal: true

    require "discorb"
    require "dotenv/load"

    client = Discorb::Client.new

    client.once :standby do
      puts "Logged in as #{client.user}"
    end

    client.run ENV["%<token>s"]
  RUBY
  ".env" => <<~BASH,
    # Put your token after `%<token>s=`
    %<token>s=
  BASH
  ".env_nc" => <<~BASH,
    %<token>s=
  BASH
  ".gitignore" => <<~GITIGNORE,
    *.gem
    *.rbc
    /.config
    /coverage/
    /InstalledFiles
    /pkg/
    /spec/reports/
    /spec/examples.txt
    /test/tmp/
    /test/version_tmp/
    /tmp/

    # Used by dotenv library to load environment variables.
    .env

    # Ignore Byebug command history file.
    .byebug_history

    ## Specific to RubyMotion:
    .dat*
    .repl_history
    build/
    *.bridgesupport
    build-iPhoneOS/
    build-iPhoneSimulator/

    ## Specific to RubyMotion (use of CocoaPods):
    #
    # We recommend against adding the Pods directory to your .gitignore. However
    # you should judge for yourself, the pros and cons are mentioned at:
    # https://guides.cocoapods.org/using/using-cocoapods.html#should-i-check-the-pods-directory-into-source-control
    #
    # vendor/Pods/

    ## Documentation cache and generated files:
    /.yardoc/
    /_yardoc/
    /doc/
    /rdoc/

    ## Environment normalization:
    /.bundle/
    /vendor/bundle
    /lib/bundler/man/

    # for a library or gem, you might want to ignore these files since the code is
    # intended to run in multiple environments; otherwise, check them in:
    # Gemfile.lock
    # .ruby-version
    # .ruby-gemset

    # unless supporting rvm < 1.11.0 or doing something fancy, ignore this:
    .rvmrc

    # Used by RuboCop. Remote config files pulled in from inherit_from directive.
    # .rubocop-https?--*

    # This gitignore is from github/gitignore.
    # https://github.com/github/gitignore/blob/master/Ruby.gitignore
  GITIGNORE
  ".gitignore_nc" => <<~GITIGNORE,
    *.gem
    *.rbc
    /.config
    /coverage/
    /InstalledFiles
    /pkg/
    /spec/reports/
    /spec/examples.txt
    /test/tmp/
    /test/version_tmp/
    /tmp/

    .env

    .byebug_history

    .dat*
    .repl_history
    build/
    *.bridgesupport
    build-iPhoneOS/
    build-iPhoneSimulator/

    /.yardoc/
    /_yardoc/
    /doc/
    /rdoc/

    /.bundle/
    /vendor/bundle
    /lib/bundler/man/

    .rvmrc
  GITIGNORE
  "Gemfile" => <<~RUBY,
    # frozen_string_literal: true

    source "https://rubygems.org"

    git_source(:github) { |repo_name| "https://github.com/\#{repo_name}" }

    gem "discorb", "~> #{Discorb::VERSION}"
    gem "dotenv", "~> 2.7"

    ruby "~> #{RUBY_VERSION.split(".")[0]}.#{RUBY_VERSION.split(".")[1]}"
  RUBY
  ".env.sample" => <<~BASH,
    %<token>s=
  BASH
  "README.md" => <<~MARKDOWN
    # %<name>s

    Welcome to your bot: %<name>s!

    TODO: Write your bot's description here.

    ## Usage

    TODO: Write your bot's usage here.

    ## Features

    TODO: Write your bot's features here.

    ## How to host

    1. Clone the repository.
    2. Run `bundle install`.
    3. Get your bot's token from the Discord developer portal.
    4. Copy `.env.sample` to `.env` and fill in the token.
    5. Run `bundle exec discorb run`.

    TODO: Write your own customizations here.

    ## License

    TODO: Write your bot's license here.
      See https://choosealicense.com/ for more information.

  MARKDOWN
}.freeze

# @private
def create_file(name)
  template_name = name
  template_name += "_nc" if !$values[:comment] && FILES.key?("#{name}_nc")
  content =
    format(FILES[template_name], token: $values[:token], name: $values[:name])
  File.write($path + "/#{name}", content, mode: "wb")
end

# @private
def make_files
  iputs "Making files..."
  create_file("main.rb")
  create_file(".env")
  sputs "Made files.\n"
end

# @private
def bundle_init
  iputs "Initializing bundle..."
  create_file("Gemfile")
  iputs "Installing gems..."
  system({ "BUNDLE_GEMFILE" => nil }, "bundle install", chdir: $path)
  sputs "Installed gems.\n"
end

# @private
def git_init
  create_file(".gitignore")
  iputs "Initializing git repository..."
  system "git init", chdir: $path
  sputs "Initialized repository.\n"
end

# @private
def make_descs
  iputs "Making descriptions..."
  create_file(".env.sample")
  create_file("README.md")
  sputs "Made descriptions.\n"
end

opt = OptionParser.new <<~BANNER
                         A tool to make a new project.

                         Usage: discorb new [options] [dir]

                                   dir                        The directory to make the files in.
                       BANNER

$values = {
  bundle: true,
  git: false,
  force: false,
  token: "TOKEN",
  descs: false,
  name: nil,
  comment: true
}

opt.on("--[no-]bundle", "Whether to use bundle. Default to true.") do |v|
  $values[:bundle] = v
end

opt.on("--[no-]git", "Whether to initialize git. Default to false.") do |v|
  $values[:git] = v
end

opt.on(
  "--[no-]descs",
  "Whether to put some file for description. Default to false."
) { |v| $values[:descs] = v }

opt.on("--[no-]comment", "Whether to write comment. Default to true.") do |v|
  $values[:comment] = v
end

opt.on(
  "-t NAME",
  "--token NAME",
  "The name of token environment variable. Default to TOKEN."
) { |v| $values[:token] = v }

opt.on(
  "-n NAME",
  "--name NAME",
  "The name of your project. Default to the directory name."
) { |v| $values[:name] = v }

opt.on(
  "--force",
  "-f",
  "Whether to force use directory. Default to false."
) { |v| $values[:force] = v }

opt.parse!(ARGV)

if (dir = ARGV[0])
  $path += "/#{dir}"
  $path = File.expand_path($path)
  dir = File.basename($path)
  if Dir.exist?($path)
    if Dir.empty?($path)
      iputs "Found \e[30m#{dir}\e[90m and empty, using this directory."
    elsif $values[:force]
      iputs "Found \e[30m#{dir}\e[90m and not empty, but force is on, using this directory."
    else
      eputs "Directory \e[31m#{dir}\e[91m already exists and not empty. Use \e[31m-f\e[91m to force."
      exit
    end
  else
    Dir.mkdir($path)
    iputs "Couldn't find \e[30m#{dir}\e[90m, created directory."
  end
  Dir.chdir($path)
else
  puts opt
  abort
end

$values[:name] ||= Dir.pwd.split("/").last

bundle_init if $values[:bundle]

make_files

make_descs if $values[:descs]

git_init if $values[:git]

sputs "\nSuccessfully made a new project at \e[32m#{Pathname.new($path).cleanpath.split[-1]}\e[92m."
