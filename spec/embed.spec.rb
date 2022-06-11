# frozen_string_literal: true

require_relative "./common"

RSpec.describe Discorb::Embed do
  it "sets title and description" do
    expect(described_class.new("title", "description").to_hash).to eq(
      {
        title: "title",
        description: "description",
        type: "rich",
      }
    )
  end

  it "sets color" do
    expect(described_class.new("t", "d", color: Discorb::Color[:blue]).to_hash).to eq(
      {
        title: "t",
        description: "d",
        color: Discorb::Color[:blue].to_i,
        type: "rich",
      }
    )
  end

  it "sets timestamp" do
    timestamp = Time.now
    expect(described_class.new("t", "d", timestamp: timestamp).to_hash).to eq(
      {
        type: "rich",
        title: "t",
        description: "d",
        timestamp: timestamp.iso8601,
      }
    )
  end

  it "sets url" do
    expect(described_class.new("t", "d", url: "url").to_hash).to eq(
      {
        type: "rich",
        title: "t",
        description: "d",
        url: "url",
      }
    )
  end

  it "adds non-inline field" do
    expect(
      described_class.new("t", "d", fields: [Discorb::Embed::Field.new("name", "value", inline: false)]).to_hash
    ).to eq(
      {
        title: "t",
        description: "d",
        fields: [
          {
            name: "name",
            value: "value",
            inline: false,
          },
        ],
        type: "rich",

      }
    )
  end

  it "adds inline field" do
    expect(
      described_class.new("t", "d", fields: [Discorb::Embed::Field.new("name", "value", inline: true)]).to_hash
    ).to eq(
      {
        title: "t",
        description: "d",
        fields: [
          {
            name: "name",
            value: "value",
            inline: true,
          },
        ],
        type: "rich",
      }
    )
  end

  describe "image" do
    let(:result) do
      {
        type: "rich",
        title: "t",
        description: "d",
        image: {
          url: "url",
        },
      }
    end

    it "sets image by initialize argument with Image class" do
      expect(
        described_class.new("t", "d", image: Discorb::Embed::Image.new("url")).to_hash
      ).to eq(result)
    end

    it "sets image by initialize argument with String" do
      expect(described_class.new("t", "d", image: "url").to_hash).to eq(result)
    end

    it "sets image by #image= with Image class" do
      embed = described_class.new("t", "d")
      embed.image = Discorb::Embed::Image.new("url")
      expect(embed.to_hash).to eq(result)
    end

    it "sets image by #image= with String" do
      embed = described_class.new("t", "d")
      embed.image = "url"
      expect(embed.to_hash).to eq(result)
    end
  end

  describe "thumbnail" do
    let(:result) do
      {
        type: "rich",
        title: "t",
        description: "d",
        thumbnail: {
          url: "url",
        },
      }
    end

    it "sets thumbnail by initialize argument with Thumbnail class" do
      expect(
        described_class.new("t", "d", thumbnail: Discorb::Embed::Thumbnail.new("url")).to_hash
      ).to eq(result)
    end

    it "sets thumbnail by initialize argument with String" do
      expect(described_class.new("t", "d", thumbnail: "url").to_hash).to eq(result)
    end

    it "sets thumbnail by #thumbnail= with Thumbnail class" do
      embed = described_class.new("t", "d")
      embed.thumbnail = Discorb::Embed::Thumbnail.new("url")
      expect(embed.to_hash).to eq(result)
    end

    it "sets thumbnail by #thumbnail= with String" do
      embed = described_class.new("t", "d")
      embed.thumbnail = "url"
      expect(embed.to_hash).to eq(result)
    end
  end

  describe "author" do
    it "sets author by initialize argument" do
      expect(
        described_class.new(
          "t", "d",
          author: Discorb::Embed::Author.new(
            "name",
            url: "url",
            icon: "icon_url",
          ),
        ).to_hash
      ).to eq(
        {
          type: "rich",
          title: "t",
          description: "d",
          author: {
            name: "name",
            url: "url",
            icon_url: "icon_url",
          },
        }
      )
    end

    it "sets author by #author=" do
      embed = described_class.new("t", "d")
      embed.author = Discorb::Embed::Author.new(
        "name",
        url: "url",
        icon: "icon_url",
      )

      expect(
        embed.to_hash
      ).to eq(
        {
          type: "rich",
          title: "t",
          description: "d",
          author: {
            name: "name",
            url: "url",
            icon_url: "icon_url",
          },
        }
      )
    end
  end

  describe "footer" do
    it "sets footer by initialize argument" do
      expect(
        described_class.new(
          "t", "d",
          footer: Discorb::Embed::Footer.new(
            "text",
            icon: "icon_url",
          ),
        ).to_hash
      ).to eq(
        {
          type: "rich",
          title: "t",
          description: "d",
          footer: {
            text: "text",
            icon_url: "icon_url",
          },
        }
      )
    end

    it "sets footer by #footer=" do
      embed = described_class.new("t", "d")
      embed.footer = Discorb::Embed::Footer.new(
        "text",
        icon: "icon_url",
      )

      expect(
        embed.to_hash
      ).to eq(
        {
          type: "rich",
          title: "t",
          description: "d",
          footer: {
            text: "text",
            icon_url: "icon_url",
          },
        }
      )
    end
  end
end
