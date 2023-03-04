# frozen_string_literal: true

%w[base guild text voice category stage thread forum dm].each do |name|
  require_relative "channel/#{name}"
end
