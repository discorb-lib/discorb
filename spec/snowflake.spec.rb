# frozen_string_literal: true

require_relative "common"

RSpec.describe Discorb::Snowflake do
  %w[
    863581274916913193
    686547120534454315
    613425648685547541
    81384788765712384
  ].each do |id|
    context "with id #{id}" do
      let(:snowflake) { described_class.new(id) }

      it "creates snowflake from string" do
        expect { described_class.new(id) }.not_to raise_error
      end

      it "creates snowflake from integer" do
        expect { described_class.new(id.to_i) }.not_to raise_error
      end

      it "returns timestamp" do
        expect(snowflake.timestamp).to satisfy do |t|
          (t.to_f * 1000).floor == (id.to_i >> 22) + 1_420_070_400_000
        end
      end

      it "returns worker id" do
        expect(snowflake.worker_id).to eq((id.to_i & 0x3E0000) >> 17)
      end

      it "returns process id" do
        expect(snowflake.process_id).to eq((id.to_i & 0x1F000) >> 12)
      end

      it "returns increment" do
        expect(snowflake.increment).to eq((id.to_i & 0xFFF) >> 0)
      end
    end
  end
end
