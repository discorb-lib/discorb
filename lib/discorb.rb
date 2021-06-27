# frozen_string_literal: true

Dir.glob("#{__dir__}/discorb/*.rb") { |f|
  Kernel.require_relative f
}
