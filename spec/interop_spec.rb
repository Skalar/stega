# frozen_string_literal: true

require "spec_helper"
require "stega/js_bridge"

RSpec.describe "JavaScript Interoperability" do
  describe "Ruby encode -> JS decode" do
    it "decodes a string encoded by Ruby" do
      value = "hello world"
      encoded = Stega.encode(value)
      decoded = Stega::JsBridge.decode(encoded)
      expect(decoded).to eq(value)
    end

    it "decodes a number encoded by Ruby" do
      value = 42
      encoded = Stega.encode(value)
      decoded = Stega::JsBridge.decode(encoded)
      expect(decoded).to eq(value)
    end

    it "decodes an object encoded by Ruby" do
      value = { "origin" => "test", "data" => { "id" => 123 } }
      encoded = Stega.encode(value)
      decoded = Stega::JsBridge.decode(encoded)
      expect(decoded).to eq(value)
    end

    it "decodes a legacy-encoded value from Ruby" do
      value = "legacy test"
      encoded = Stega.legacy_encode(value)
      decoded = Stega::JsBridge.decode(encoded)
      expect(decoded).to eq(value)
    end
  end

  describe "JS encode -> Ruby decode" do
    it "decodes a string encoded by JS" do
      value = "hello world"
      encoded = Stega::JsBridge.encode(value)
      decoded = Stega.decode(encoded)
      expect(decoded).to eq(value)
    end

    it "decodes a number encoded by JS" do
      value = 42
      encoded = Stega::JsBridge.encode(value)
      decoded = Stega.decode(encoded)
      expect(decoded).to eq(value)
    end

    it "decodes an object encoded by JS" do
      value = { "origin" => "test", "data" => { "id" => 123 } }
      encoded = Stega::JsBridge.encode(value)
      decoded = Stega.decode(encoded)
      expect(decoded).to eq(value)
    end

    it "decodes a legacy-encoded value from JS" do
      value = "legacy test"
      encoded = Stega::JsBridge.legacy_encode(value)
      decoded = Stega.decode(encoded)
      expect(decoded).to eq(value)
    end
  end

  describe "Sanity encode_source_map interoperability" do
    let(:result) { { "title" => "Hello World" } }
    let(:source_map) do
      {
        "documents" => [{ "_id" => "doc1", "_type" => "post" }],
        "paths" => ["$['title']"],
        "mappings" => {
          "$['title']" => {
            "type" => "value",
            "source" => { "document" => 0, "path" => 0, "type" => "documentValue" }
          }
        }
      }
    end
    let(:config) { { enabled: true, studio_url: "https://studio.sanity.io" } }

    it "Ruby encode_source_map output is decodable by JS" do
      encoded = Stega::Sanity.encode_source_map(result, source_map, config)
      decoded = Stega::JsBridge.decode(encoded["title"])

      expect(decoded["origin"]).to eq("sanity.io")
    end

    it "JS stegaEncodeSourceMap output is decodable by Ruby" do
      encoded = Stega::JsBridge.sanity_encode_source_map(result, source_map, config)
      decoded = Stega.decode(encoded["title"])

      expect(decoded["origin"]).to eq("sanity.io")
    end

    it "Ruby and JS produce decodable outputs with matching origins" do
      ruby_encoded = Stega::Sanity.encode_source_map(result, source_map, config)
      js_encoded = Stega::JsBridge.sanity_encode_source_map(result, source_map, config)

      ruby_decoded = Stega.decode(ruby_encoded["title"])
      js_decoded = Stega.decode(js_encoded["title"])

      expect(ruby_decoded["origin"]).to eq(js_decoded["origin"])
      expect(ruby_decoded["origin"]).to eq("sanity.io")
    end

    it "both handle nested objects consistently" do
      nested_result = { "author" => { "name" => "John" } }
      nested_source_map = {
        "documents" => [{ "_id" => "doc1", "_type" => "post" }],
        "paths" => ["$['author']['name']"],
        "mappings" => {
          "$['author']['name']" => {
            "type" => "value",
            "source" => { "document" => 0, "path" => 0, "type" => "documentValue" }
          }
        }
      }

      ruby_encoded = Stega::Sanity.encode_source_map(nested_result, nested_source_map, config)
      js_encoded = Stega::JsBridge.sanity_encode_source_map(nested_result, nested_source_map, config)

      ruby_decoded = Stega.decode(ruby_encoded["author"]["name"])
      js_decoded = Stega.decode(js_encoded["author"]["name"])

      expect(ruby_decoded["origin"]).to eq(js_decoded["origin"])
    end

    it "both handle arrays consistently" do
      array_result = { "tags" => ["ruby", "javascript"] }
      array_source_map = {
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

      ruby_encoded = Stega::Sanity.encode_source_map(array_result, array_source_map, config)
      js_encoded = Stega::JsBridge.sanity_encode_source_map(array_result, array_source_map, config)

      ruby_decoded_0 = Stega.decode(ruby_encoded["tags"][0])
      js_decoded_0 = Stega.decode(js_encoded["tags"][0])

      expect(ruby_decoded_0["origin"]).to eq(js_decoded_0["origin"])
    end
  end
end
