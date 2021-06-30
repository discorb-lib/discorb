# frozen_string_literal: true

Dir.glob("#{__dir__}/discorb/*.rb") do |f|
  Kernel.require_relative f
end
