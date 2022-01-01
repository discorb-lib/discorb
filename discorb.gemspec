# frozen_string_literal: true

require_relative "lib/discorb/common"

Gem::Specification.new do |spec|
  spec.name = "discorb"
  spec.version = Discorb::VERSION
  spec.authors = ["sevenc-nanashi"]
  spec.email = ["sevenc-nanashi@sevenbot.jp"]

  spec.summary = "A Discord API wrapper for Ruby, Using socketry/async."
  spec.description = <<~RDOC
    == discorb
    discorb is a Discord API wrapper for Ruby, Using {socketry/async}[https://github.com/socketry/async].

    === Contributing
    Bug reports, feature requests, and pull requests are welcome on {the GitHub repository}[https://github.com/discorb-lib/discorb].

    === License
    This gem is licensed under the MIT License.

  RDOC
  spec.homepage = "https://github.com/discorb-lib/discorb"
  spec.license = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 3.0.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/discorb-lib/discorb"
  spec.metadata["changelog_uri"] = "https://discorb-lib.github.io/file.Changelog.html"
  spec.metadata["documentation_uri"] = "https://discorb-lib.github.io"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "async", "~> 1.30.1"
  spec.add_dependency "async-http", "~> 0.56.5"
  spec.add_dependency "async-websocket", "~> 0.19.0"

  spec.add_dependency "mime-types", "~> 3.3"
  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end
