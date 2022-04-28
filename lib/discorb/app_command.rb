# frozen_string_literal: true
%w[common command handler].each do |file|
  require_relative "app_command/#{file}.rb"
end
