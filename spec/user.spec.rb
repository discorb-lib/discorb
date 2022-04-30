# frozen_string_literal: true

require_relative "./common"

RSpec.describe Discorb::User do
  %w[user bot].each do |data_name|
    let(:data) { JSON.load_file(__dir__ + "/payloads/users/#{data_name}.json", symbolize_names: true) }
    let(:user) { described_class.new(client, data) }
    it "initializes successfully" do
      expect { user }.not_to raise_error
    end

    describe "parsing" do
      specify "#id returns the id as Snowflake" do
        expect(user.id).to be_a Discorb::Snowflake
        expect(user.id).to eq data[:id]
      end

      specify "#name returns the name" do
        expect(user.name).to eq data[:username]
      end

      specify "#avatar returns Asset object" do
        expect(user.avatar).to be_a Discorb::Asset
      end
    end

    describe "helpers" do
      specify "#to_s returns name with `name#discriminator` format" do
        expect(user.to_s).to eq "#{data[:username]}##{data[:discriminator]}"
      end

      specify "#mention returns `<@user_id>`" do
        expect(user.mention).to eq "<@#{data[:id]}>"
      end

      specify "#bot? returns true if user is bot" do
        expect(user.bot?).to eq data[:bot] == true
      end
    end
  end
end
