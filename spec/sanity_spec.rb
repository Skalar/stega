# frozen_string_literal: true

RSpec.describe Stega::Sanity do
  describe ".encode_source_map" do
    it "raises TypeError when enabled is false" do
      config = { enabled: false }
      expect { Stega::Sanity.encode_source_map({}, {}, config) }
        .to raise_error(TypeError, /enabled must be true/)
    end

    it "returns result unchanged when source_map is nil" do
      config = { enabled: true, studio_url: "https://studio.sanity.io" }
      result = { "title" => "Hello" }
      expect(Stega::Sanity.encode_source_map(result, nil, config)).to eq(result)
    end

    it "raises TypeError when studio_url is not defined" do
      config = { enabled: true }
      expect { Stega::Sanity.encode_source_map({}, {}, config) }
        .to raise_error(TypeError, /studio_url must be defined/)
    end

    it "encodes string values from source map" do
      result = { "title" => "Hello World" }
      source_map = {
        "documents" => [{ "_id" => "doc1", "_type" => "post" }],
        "paths" => ["title"],
        "mappings" => { "title" => { "source" => { "document" => 0, "path" => 0 } } }
      }
      config = { enabled: true, studio_url: "https://studio.sanity.io" }

      encoded = Stega::Sanity.encode_source_map(result, source_map, config)
      decoded = Stega.decode(encoded["title"])

      expect(decoded["origin"]).to eq("sanity.io")
      expect(decoded["href"]).to include("doc1")
    end
  end
end
