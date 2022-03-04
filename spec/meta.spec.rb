# frozen_string_literal: true
require "discorb"
require "open3"

RSpec.describe do
  ObjectSpace.each_object(Class).filter { |c| c.name&.start_with?("Discorb::") }.each do |klass|
    next if klass.ancestors.include? StandardError
    specify "#{klass.name} should have #inspect" do
      expect(klass.instance_methods(false)).to include(:inspect)
    end
  end
end
