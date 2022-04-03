# frozen_string_literal: true
require "discorb"
require "open3"

RSpec.describe "Classes" do
  ObjectSpace.each_object(Class).filter { |c| c.name&.start_with?("Discorb::") }.each do |klass|
    next if klass.ancestors.include? StandardError
    specify "#{klass.name} should have #inspect" do
      expect(klass.instance_method(:inspect)).to be_truthy
      expect(klass.instance_method(:inspect).source_location).to be_truthy
    end
  end
end
