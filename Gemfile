# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in discorb.gemspec
gemspec

gem "rake", "~> 13.0"

group :development, optional: true do
  gem "rufo", "~> 0.13.0"
  gem "sord", "~> 3.0.1"
end

group :docs, optional: true do
  gem "redcarpet"
  gem "yard", "~> 0.9.26"
  gem "gettext", "~> 3.4.1"
  gem "crowdin-api", "~> 1.0"
  gem "rubyzip", "~> 2.3"
end

group :lint, optional: true do
  gem "rubocop", "~> 1.25"
end
