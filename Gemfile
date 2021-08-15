# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in discorb.gemspec
gemspec

gem 'rake', '~> 13.0'

gem 'async'
gem 'async-http'
gem 'async-websocket'

gem 'mime-types', '~> 3.3'

group :ci, optional: true do
  gem 'rubocop', '~> 1.17'
end

group :colorize, optional: true do
  gem 'colorize', '~> 0.8.1'
end

group :debug, optional: true do
  gem 'pry', '~> 0.14.1'
  gem 'ricecream', '~> 0.2.0'
end

group :docs, optional: true do
  gem 'redcarpet'
  gem 'yard', '~> 0.9.26'
end
