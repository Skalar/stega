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
        "paths" => ["$['title']"],
        "mappings" => {
          "$['title']" => {
            "type" => "value",
            "source" => { "document" => 0, "path" => 0, "type" => "documentValue" }
          }
        }
      }
      config = { enabled: true, studio_url: "https://studio.sanity.io" }

      encoded = Stega::Sanity.encode_source_map(result, source_map, config)
      decoded = Stega.decode(encoded["title"])

      expect(decoded["origin"]).to eq("sanity.io")
      expect(decoded["href"]).to include("doc1")
    end

    it "skips URL values by default" do
      result = { "url" => "https://example.com" }
      source_map = {
        "documents" => [{ "_id" => "doc1", "_type" => "post" }],
        "paths" => ["$['url']"],
        "mappings" => {
          "$['url']" => {
            "type" => "value",
            "source" => { "document" => 0, "path" => 0, "type" => "documentValue" }
          }
        }
      }
      config = { enabled: true, studio_url: "https://studio.sanity.io" }

      encoded = Stega::Sanity.encode_source_map(result, source_map, config)
      expect(encoded["url"]).to eq("https://example.com")
    end

    it "uses custom filter when provided" do
      result = { "title" => "skip-me", "other" => "encode-me" }
      source_map = {
        "documents" => [{ "_id" => "doc1", "_type" => "post" }],
        "paths" => ["$['title']", "$['other']"],
        "mappings" => {
          "$['title']" => {
            "type" => "value",
            "source" => { "document" => 0, "path" => 0, "type" => "documentValue" }
          },
          "$['other']" => {
            "type" => "value",
            "source" => { "document" => 0, "path" => 1, "type" => "documentValue" }
          }
        }
      }
      filter = ->(ctx) { ctx[:value] != "skip-me" }
      config = { enabled: true, studio_url: "https://studio.sanity.io", filter: filter }

      encoded = Stega::Sanity.encode_source_map(result, source_map, config)

      expect(encoded["title"]).to eq("skip-me")
      expect(Stega.decode(encoded["other"])).to include("origin" => "sanity.io")
    end

    it "creates edit URLs with document metadata" do
      result = { "title" => "Hello" }
      source_map = {
        "documents" => [{ "_id" => "doc123", "_type" => "article" }],
        "paths" => ["$['content']['title']"],
        "mappings" => {
          "$['title']" => {
            "type" => "value",
            "source" => { "document" => 0, "path" => 0, "type" => "documentValue" }
          }
        }
      }
      config = { enabled: true, studio_url: "https://my-studio.sanity.studio" }

      encoded = Stega::Sanity.encode_source_map(result, source_map, config)
      decoded = Stega.decode(encoded["title"])

      expect(decoded["href"]).to include("my-studio.sanity.studio")
      expect(decoded["href"]).to include("intent/edit")
      expect(decoded["href"]).to include("id=doc123")
      expect(decoded["href"]).to include("type=article")
    end

    it "includes dataset and projectId by default" do
      result = { "title" => "Hello" }
      source_map = {
        "documents" => [{ "_id" => "doc1", "_type" => "post", "_projectId" => "proj123", "_dataset" => "production" }],
        "paths" => ["$['title']"],
        "mappings" => {
          "$['title']" => {
            "type" => "value",
            "source" => { "document" => 0, "path" => 0, "type" => "documentValue" }
          }
        }
      }
      config = { enabled: true, studio_url: "https://studio.sanity.io" }

      encoded = Stega::Sanity.encode_source_map(result, source_map, config)
      decoded = Stega.decode(encoded["title"])

      expect(decoded["href"]).to include("projectId=proj123")
      expect(decoded["href"]).to include("dataset=production")
    end

    it "omits dataset/projectId when omit_cross_dataset_reference_data is true" do
      result = { "title" => "Hello" }
      source_map = {
        "documents" => [{ "_id" => "doc1", "_type" => "post", "_projectId" => "proj123", "_dataset" => "production" }],
        "paths" => ["$['title']"],
        "mappings" => {
          "$['title']" => {
            "type" => "value",
            "source" => { "document" => 0, "path" => 0, "type" => "documentValue" }
          }
        }
      }
      config = { enabled: true, studio_url: "https://studio.sanity.io", omit_cross_dataset_reference_data: true }

      encoded = Stega::Sanity.encode_source_map(result, source_map, config)
      decoded = Stega.decode(encoded["title"])

      expect(decoded["href"]).not_to include("projectId")
      expect(decoded["href"]).not_to include("dataset")
    end

    it "encodes strings in nested objects" do
      result = { "author" => { "name" => "John" } }
      source_map = {
        "documents" => [{ "_id" => "doc1", "_type" => "post" }],
        "paths" => ["$['author']['name']"],
        "mappings" => {
          "$['author']['name']" => {
            "type" => "value",
            "source" => { "document" => 0, "path" => 0, "type" => "documentValue" }
          }
        }
      }
      config = { enabled: true, studio_url: "https://studio.sanity.io" }

      encoded = Stega::Sanity.encode_source_map(result, source_map, config)
      decoded = Stega.decode(encoded["author"]["name"])

      expect(decoded["origin"]).to eq("sanity.io")
      expect(decoded["href"]).to include("doc1")
    end

    it "encodes strings in arrays" do
      result = { "tags" => ["ruby", "javascript"] }
      source_map = {
        "documents" => [{ "_id" => "doc1", "_type" => "post" }],
        "paths" => ["$['tags'][0]", "$['tags'][1]"],
        "mappings" => {
          "$['tags'][0]" => {
            "type" => "value",
            "source" => { "document" => 0, "path" => 0, "type" => "documentValue" }
          },
          "$['tags'][1]" => {
            "type" => "value",
            "source" => { "document" => 0, "path" => 1, "type" => "documentValue" }
          }
        }
      }
      config = { enabled: true, studio_url: "https://studio.sanity.io" }

      encoded = Stega::Sanity.encode_source_map(result, source_map, config)

      decoded0 = Stega.decode(encoded["tags"][0])
      decoded1 = Stega.decode(encoded["tags"][1])

      expect(decoded0["origin"]).to eq("sanity.io")
      expect(decoded1["origin"]).to eq("sanity.io")
    end
  end
end
