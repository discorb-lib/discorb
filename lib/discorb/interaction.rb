%w[root response command components autocomplete].each do |file|
  require_relative "interaction/#{file}.rb"
end
