# frozen_string_literal: true

RSpec.describe Stega do
  describe ".encode" do
    it "returns a string" do
      result = Stega.encode("test")
      expect(result).to be_a(String)
    end
  end

  describe ".decode" do
    it "can decode what encode produces" do
      encoded = Stega.encode("hello")
      decoded = Stega.decode(encoded)
      expect(decoded).to eq("hello")
    end
  end

  describe "round-trip encoding" do
    it "preserves strings" do
      value = "hello world"
      expect(Stega.decode(Stega.encode(value))).to eq(value)
    end

    it "preserves numbers" do
      value = 12_345
      expect(Stega.decode(Stega.encode(value))).to eq(value)
    end

    it "preserves complex objects" do
      value = { "foo" => "bar", "nested" => { "arr" => [1, 2, 3] } }
      expect(Stega.decode(Stega.encode(value))).to eq(value)
    end
  end

  describe ".combine" do
    it "appends encoded data to visible string" do
      result = Stega.combine("visible", { "key" => "value" })
      expect(result).to start_with("visible")
      expect(result.length).to be > "visible".length
      expect(Stega.decode(result)).to eq({ "key" => "value" })
    end

    it "with skip mode returns only visible string" do
      result = Stega.combine("visible", { "key" => "value" }, :skip)
      expect(result).to eq("visible")
    end

    it "with skip=true returns only visible string" do
      result = Stega.combine("visible", { "key" => "value" }, true)
      expect(result).to eq("visible")
    end

    it "auto-skips URLs" do
      result = Stega.combine("https://example.com/path", { "key" => "value" })
      expect(result).to eq("https://example.com/path")
    end

    it "auto-skips relative URLs" do
      result = Stega.combine("/path/to/resource", { "key" => "value" })
      expect(result).to eq("/path/to/resource")
    end

    it "auto-skips dates" do
      result = Stega.combine("2024-01-15", { "key" => "value" })
      expect(result).to eq("2024-01-15")
    end

    it "auto-skips ISO date strings" do
      result = Stega.combine("2024-01-15T10:30:00Z", { "key" => "value" })
      expect(result).to eq("2024-01-15T10:30:00Z")
    end
  end

  describe ".split" do
    it "separates visible and encoded parts" do
      combined = Stega.combine("visible", { "data" => 123 })
      result = Stega.split(combined)

      expect(result[:cleaned]).to eq("visible")
      expect(result[:encoded]).not_to be_empty
    end

    it "returns empty encoded for plain strings" do
      result = Stega.split("just plain text")
      expect(result[:cleaned]).to eq("just plain text")
      expect(result[:encoded]).to eq("")
    end

    it "cleaned removes all invisible characters" do
      combined = Stega.combine("hello", "world")
      result = Stega.split(combined)
      expect(result[:cleaned]).to eq("hello")
      expect(result[:cleaned].length).to eq(5)
    end
  end

  describe ".clean" do
    it "removes stega data from strings" do
      combined = Stega.combine("visible", { "hidden" => "data" })
      expect(Stega.clean(combined)).to eq("visible")
    end

    it "handles nested objects" do
      obj = {
        "name" => Stega.combine("John", { "edit" => true }),
        "items" => [
          Stega.combine("item1", { "id" => 1 }),
          Stega.combine("item2", { "id" => 2 })
        ]
      }
      cleaned = Stega.clean(obj)

      expect(cleaned["name"]).to eq("John")
      expect(cleaned["items"]).to eq(%w[item1 item2])
    end

    it "handles nil gracefully" do
      expect(Stega.clean(nil)).to be_nil
    end

    it "handles false gracefully" do
      expect(Stega.clean(false)).to eq(false)
    end
  end

  describe "REGEX" do
    it "matches encoded strings" do
      encoded = Stega.encode("test")
      expect(encoded).to match(Stega::REGEX)
    end

    it "does not match plain text" do
      expect("Hello, World!").not_to match(Stega::REGEX)
    end

    it "does not match short sequences of invisible characters" do
      # Only 3 invisible chars - should not match (minimum is 4)
      short = "\u200B\u200C\u200D"
      expect(short).not_to match(Stega::REGEX)
    end
  end

  describe ".decode_all" do
    it "returns array of payloads" do
      encoded1 = Stega.encode({ "first" => 1 })
      encoded2 = Stega.encode({ "second" => 2 })
      combined = "prefix#{encoded1}middle#{encoded2}suffix"

      results = Stega.decode_all(combined)
      expect(results).to be_an(Array)
      expect(results.length).to eq(2)
      expect(results[0]).to eq({ "first" => 1 })
      expect(results[1]).to eq({ "second" => 2 })
    end

    it "returns nil for non-encoded strings" do
      result = Stega.decode_all("just plain text")
      expect(result).to be_nil
    end
  end

  describe ".legacy_encode" do
    it "produces decodable output" do
      encoded = Stega.legacy_encode({ "test" => "value" })
      decoded = Stega.decode(encoded)
      expect(decoded).to eq({ "test" => "value" })
    end

    it "produces different output than modern encode" do
      value = "test"
      legacy = Stega.legacy_encode(value)
      modern = Stega.encode(value)

      expect(legacy).not_to eq(modern)
    end

    it "raises error for non-ASCII characters" do
      expect { Stega.legacy_encode("\u{1F600}") }.to raise_error(ArgumentError)
    end
  end

  describe "cross-compatibility" do
    it "decode works with both encoding formats" do
      modern = Stega.encode("modern")
      legacy = Stega.legacy_encode("legacy")

      expect(Stega.decode(modern)).to eq("modern")
      expect(Stega.decode(legacy)).to eq("legacy")
    end
  end
end
