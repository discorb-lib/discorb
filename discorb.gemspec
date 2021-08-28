# frozen_string_literal: true

require_relative "lib/discorb/common"

Gem::Specification.new do |spec|
  spec.name = "discorb"
  spec.version = Discorb::VERSION
  spec.authors = ["sevenc-nanashi"]
  spec.email = ["sevenc-nanashi@sevenbot.jp"]

  spec.summary = "discorb is a Discord API wrapper for Ruby."
  spec.description = File.read(File.join(__dir__, "README.md"))
  spec.homepage = "https://github.com/sevenc-nanashi/discorb"
  spec.license = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 3.0.0")

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/sevenc-nanashi/discorb"
  spec.metadata["changelog_uri"] = "https://github.com/sevenc-nanashi/discorb/blob/main/Changelog.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end
