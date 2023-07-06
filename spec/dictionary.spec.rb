# frozen_string_literal: true

require_relative "common"

RSpec.describe Discorb::Dictionary do
  let(:dict) { described_class.new({ foo: :bar, fizz: :buzz, hoge: :fuga }) }

  describe ".new" do
    it "creates an empty dictionary" do
      expect { described_class.new }.not_to raise_error
    end

    it "creates with elements" do
      expect do
        described_class.new({ foo: :bar, fizz: :buzz })
      end.not_to raise_error
    end
  end

  describe "#[]" do
    it "transforms non-string keys to strings" do
      expect(dict[:foo]).to be :bar
      expect(dict["foo"]).to be :bar
    end

    it "returns value with integer index" do
      expect(dict[0]).to be :bar
    end

    it "sorts keys" do
      new_dict =
        described_class.new(
          { hoge: :fuga, foo: :bar, fizz: :buzz },
          sort: proc { |a, _b| a.to_s }
        )
      expect(new_dict[0]).to be :buzz
      new_dict[:a] = :b
      expect(new_dict[0]).to be :b
    end

    it "follows limits" do
      new_dict =
        described_class.new({ hoge: :fuga, foo: :bar, fizz: :buzz }, limit: 4)
      expect(new_dict.size).to eq 3
      new_dict[:a] = :b
      new_dict[:b] = :c
      expect(new_dict.size).to eq 4
    end
  end

  describe "#to_h" do
    it "returns hash" do
      expect(dict.to_h).to eq(
        { "foo" => :bar, "fizz" => :buzz, "hoge" => :fuga }
      )
    end
  end

  describe "#values" do
    it "returns values" do
      expect(dict.values).to eq %i[bar buzz fuga]
    end
  end

  describe "#has?" do
    it "returns true if value exists" do
      expect(dict.has?(:foo)).to be true
      expect(dict.has?("foo")).to be true
      expect(dict.has?(:bar)).to be false
    end
  end

  describe "#merge" do
    it "merges dictionary" do
      dict2 = described_class.new({ piyo: :poyo, fizz: :buzz2 })
      dict.merge(dict2)
      expect(dict.to_h).to eq(
        { "foo" => :bar, "fizz" => :buzz2, "hoge" => :fuga, "piyo" => :poyo }
      )
    end
  end

  describe "#remove" do
    it "removes item" do
      dict.remove("foo")
      expect(dict.to_h).to eq({ "fizz" => :buzz, "hoge" => :fuga })
    end
  end
end
