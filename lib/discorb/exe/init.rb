# description: Make files for the discorb project.

require "optparse"
require "discorb"
require_relative "../utils/colored_puts"

$path = Dir.pwd

# @!visibility private
FILES = {
  "main.rb" => <<~'RUBY',
    require "discorb"
    require "dotenv"

    Dotenv.load  # Loads .env file

    client = Discorb::Client.new  # Create client for connecting to Discord

    client.once :standby do
      puts "Logged in as #{client.user}"  # Prints username of logged in user
    end

    client.run ENV["%<token>s"]  # Starts client
  RUBY
  ".env" => <<~BASH,
    %<token>s=Y0urB0tT0k3nHer3.Th1sT0ken.W0ntWorkB3c4useItH4sM34n1ng
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
  "Gemfile" => <<~RUBY,
    # frozen_string_literal: true

    source "https://rubygems.org"

    git_source(:github) { |repo_name| "https://github.com/\#{repo_name}" }

    gem "discorb", "~> #{Discorb::VERSION}"
    gem "dotenv", "~> 2.7"
  RUBY
  ".env.sample" => <<~BASH,
    %<token>s=
  BASH
  "README.md" => <<~MARKDOWN,
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
      https://rubygems.org/gems/license-cli may be useful.

  MARKDOWN
}

# @!visibility private
def create_file(name)
  File.write($path + "/#{name}", format(FILES[name], token: $values[:token], name: $values[:name]), mode: "wb")
end

# @!visibility private
def make_files
  iputs "Making files..."
  create_file("main.rb")
  create_file(".env")
  sputs "Made files.\n"
end

# @!visibility private
def bundle_init
  iputs "Initializing bundle..."
  create_file("Gemfile")
  iputs "Installing gems..."
  system "bundle install"
  sputs "Installed gems.\n"
end

# @!visibility private
def git_init
  create_file(".gitignore")
  iputs "Initializing git repository..."
  system "git init"
  system "git add ."
  system "git commit -m \"Initial commit\""
  sputs "Initialized repository, use " +
          "\e[32mgit commit --amend -m '...'\e[92m" +
          " to change commit message of initial commit.\n"
end

# @!visibility private
def make_descs
  iputs "Making descriptions..."
  create_file(".env.sample")
  create_file("README.md")
  sputs "Made descriptions.\n"
end

opt = OptionParser.new <<~BANNER
                         A tool to make a new project.

                         Usage: discorb init [options] [dir]

                                   dir                        The directory to make the files in.
                       BANNER

$values = {
  bundle: true,
  git: false,
  force: false,
  token: "TOKEN",
  descs: false,
  name: nil,
}

opt.on("--[no-]bundle", "Whether to use bundle. Default to true.") do |v|
  $values[:bundle] = v
end

opt.on("--[no-]git", "Whether to initialize git. Default to false.") do |v|
  $values[:git] = v
end

opt.on("--[no-]descs", "Whether to put some file for description. Default to false.") do |v|
  $values[:descs] = v
end

opt.on("-t NAME", "--token NAME", "The name of token environment variable. Default to TOKEN.") do |v|
  $values[:token] = v
end

opt.on("-n NAME", "--name NAME", "The name of your project. Default to the directory name.") do |v|
  $values[:name] = v
end

opt.on("-f", "--force", "Whether to force use directory. Default to false.") do |v|
  $values[:force] = v
end

ARGV.delete_at(0)

opt.parse!(ARGV)

if (dir = ARGV[0])
  $path += "/#{dir}"
  if Dir.exist?($path)
    if Dir.empty?($path)
      iputs "Found \e[30m#{dir}\e[90m and empty, using this directory."
    else
      if $values[:force]
        iputs "Found \e[30m#{dir}\e[90m and not empty, but force is on, using this directory."
      else
        eputs "Directory \e[31m#{dir}\e[91m already exists and not empty. Use \e[31m-f\e[91m to force."
        exit
      end
    end
  else
    Dir.mkdir($path)
    iputs "Couldn't find \e[30m#{dir}\e[90m, created directory."
  end
  Dir.chdir($path)
end

$values[:name] ||= Dir.pwd.split("/").last

bundle_init if $values[:bundle]

make_files

git_init if $values[:git]

make_descs if $values[:descs]

sputs "\nSuccessfully made a new project at \e[32m#{$path}\e[92m."
