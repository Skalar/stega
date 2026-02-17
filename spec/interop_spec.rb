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
end
