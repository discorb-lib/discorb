# frozen_string_literal: true

%w[root response command components autocomplete modal].each do |file|
  require_relative "interaction/#{file}.rb"
end
