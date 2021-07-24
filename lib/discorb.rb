# frozen_string_literal: true

# require 'ricecream'
Dir.glob("#{__dir__}/discorb/*.rb") do |f|
  Kernel.require_relative f
end
