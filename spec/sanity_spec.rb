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

    context "with symbol-keyed source maps (interop with external SanityStega)" do
      let(:config) { { enabled: true, studio_url: "http://studio.test" } }

      it "appends invisible stega characters to mapped string values" do
        result = { "title" => "Hello World" }
        source_map = {
          documents: [{ _id: "doc-1", _type: "page" }],
          paths: ["$['title']"],
          mappings: {
            "$['title']" => {
              source: { type: "documentValue", document: 0, path: 0 }
            }
          }
        }

        encoded = Stega::Sanity.encode_source_map(result, source_map, config)
        encoded_title = encoded["title"]

        expect(encoded_title).to start_with("Hello World")
        expect(encoded_title.length).to be > "Hello World".length

        clean = encoded_title.gsub(/[\u200B\u200C\u200D\uFEFF]/, "")
        expect(clean).to eq("Hello World")
      end

      it "encodes a payload that decodes to the correct edit intent URL" do
        result = { "title" => "Test" }
        source_map = {
          documents: [{ _id: "abc-123", _type: "article" }],
          paths: ["$['title']"],
          mappings: {
            "$['title']" => {
              source: { type: "documentValue", document: 0, path: 0 }
            }
          }
        }

        encoded = Stega::Sanity.encode_source_map(result, source_map, config)
        decoded = Stega.decode(encoded["title"])

        expect(decoded["origin"]).to eq("sanity.io")
        expect(decoded["href"]).to include("intent/edit/")
          .and include("mode=presentation")
          .and include("id=abc-123")
          .and include("type=article")
      end

      context "with internal Sanity keys" do
        let(:result) do
          {
            "_id" => "doc-1",
            "_type" => "page",
            "_ref" => "ref-1",
            "_key" => "key-1",
            "slug" => { "current" => "about" },
            "title" => "About Us"
          }
        end
        let(:source_map) do
          {
            documents: [{ _id: "doc-1", _type: "page" }],
            paths: ["$['title']"],
            mappings: {
              "$['title']" => { source: { type: "documentValue", document: 0, path: 0 } }
            }
          }
        end
        let(:encoded) { Stega::Sanity.encode_source_map(result, source_map, config) }

        { "_id" => "doc-1", "_type" => "page", "_ref" => "ref-1", "_key" => "key-1", "slug" => { "current" => "about" } }.each do |key, value|
          it "does not encode #{key}" do
            expect(encoded[key]).to eq(value)
          end
        end

        it "still encodes mapped non-internal keys" do
          expect(encoded["title"].length).to be > "About Us".length
        end
      end

      it "traverses nested hashes and arrays to encode deeply nested strings" do
        result = {
          "blocks" => [
            {
              "_type" => "block",
              "children" => [
                { "_type" => "span", "text" => "Nested text" }
              ]
            }
          ]
        }
        source_map = {
          documents: [{ _id: "doc-1", _type: "page" }],
          paths: ["$['blocks'][0]['children'][0]['text']"],
          mappings: {
            "$['blocks'][0]['children'][0]['text']" => {
              source: { type: "documentValue", document: 0, path: 0 }
            }
          }
        }

        encoded = Stega::Sanity.encode_source_map(result, source_map, config)

        span = encoded["blocks"][0]["children"][0]
        expect(span["_type"]).to eq("span")
        expect(span["text"]).to start_with("Nested text")
        expect(span["text"].length).to be > "Nested text".length
      end

      it "leaves unmapped strings unchanged" do
        result = { "title" => "Mapped", "description" => "Not mapped" }
        source_map = {
          documents: [{ _id: "doc-1", _type: "page" }],
          paths: ["$['title']"],
          mappings: {
            "$['title']" => { source: { type: "documentValue", document: 0, path: 0 } }
          }
        }

        encoded = Stega::Sanity.encode_source_map(result, source_map, config)

        expect(encoded["title"].length).to be > "Mapped".length
        expect(encoded["description"]).to eq("Not mapped")
      end

      it "preserves non-string values like numbers and booleans" do
        result = { "title" => "Hello", "count" => 42, "active" => true }
        source_map = {
          documents: [{ _id: "doc-1", _type: "page" }],
          paths: [],
          mappings: {}
        }

        encoded = Stega::Sanity.encode_source_map(result, source_map, config)

        expect(encoded["count"]).to eq(42)
        expect(encoded["active"]).to be(true)
      end

      it "handles an empty mappings hash gracefully" do
        result = { "title" => "Hello" }
        source_map = { documents: [], paths: [], mappings: {} }

        encoded = Stega::Sanity.encode_source_map(result, source_map, config)

        expect(encoded).to eq({ "title" => "Hello" })
      end

      it "handles multiple documents in the source map" do
        result = {
          "title" => "Page Title",
          "footer" => "Footer Text"
        }
        source_map = {
          documents: [
            { _id: "page-1", _type: "page" },
            { _id: "settings-1", _type: "siteSettings" }
          ],
          paths: ["$['title']", "$['footer']"],
          mappings: {
            "$['title']" => { source: { type: "documentValue", document: 0, path: 0 } },
            "$['footer']" => { source: { type: "documentValue", document: 1, path: 1 } }
          }
        }

        encoded = Stega::Sanity.encode_source_map(result, source_map, config)

        title_payload = Stega.decode(encoded["title"])
        footer_payload = Stega.decode(encoded["footer"])

        expect(title_payload["href"]).to include("id=page-1").and include("type=page")
        expect(footer_payload["href"]).to include("id=settings-1").and include("type=siteSettings")
      end

      it "uses semicolon-delimited router params in edit URL" do
        result = { "title" => "Hello" }
        source_map = {
          documents: [{ _id: "doc-1", _type: "page" }],
          paths: ["$['title']"],
          mappings: {
            "$['title']" => { source: { type: "documentValue", document: 0, path: 0 } }
          }
        }

        encoded = Stega::Sanity.encode_source_map(result, source_map, config)
        decoded = Stega.decode(encoded["title"])

        expect(decoded["href"]).to match(%r{/intent/edit/mode=presentation;id=doc-1;type=page;path=})
      end

      it "includes perspective and baseUrl in edit URL query params" do
        result = { "title" => "Hello" }
        source_map = {
          documents: [{ _id: "doc-1", _type: "page" }],
          paths: ["$['title']"],
          mappings: {
            "$['title']" => { source: { type: "documentValue", document: 0, path: 0 } }
          }
        }

        encoded = Stega::Sanity.encode_source_map(result, source_map, config)
        decoded = Stega.decode(encoded["title"])

        uri = URI.parse(decoded["href"])
        params = URI.decode_www_form(uri.query).to_h

        expect(params["perspective"]).to eq("previewDrafts")
        expect(params["baseUrl"]).to eq("http://studio.test")
      end

      it "converts JSON path to studio path format in edit URL" do
        result = { "body" => [{ "children" => [{ "text" => "Hello" }] }] }
        source_map = {
          documents: [{ _id: "doc-1", _type: "page" }],
          paths: ["$['body'][0]['children'][0]['text']"],
          mappings: {
            "$['body'][0]['children'][0]['text']" => {
              source: { type: "documentValue", document: 0, path: 0 }
            }
          }
        }

        encoded = Stega::Sanity.encode_source_map(result, source_map, config)
        decoded = Stega.decode(encoded["body"][0]["children"][0]["text"])

        expect(decoded["href"]).to include("path=body%5B0%5D.children%5B0%5D.text")
      end

      it "resolves mappings by walking up the path" do
        result = { "content" => { "body" => { "title" => "Hello" } } }
        source_map = {
          documents: [{ _id: "doc-1", _type: "page" }],
          paths: ["$['content']"],
          mappings: {
            "$['content']" => { source: { type: "documentValue", document: 0, path: 0 } }
          }
        }

        encoded = Stega::Sanity.encode_source_map(result, source_map, config)
        decoded = Stega.decode(encoded["content"]["body"]["title"])

        expect(decoded["origin"]).to eq("sanity.io")
        expect(decoded["href"]).to include("id=doc-1")
      end
    end
  end
end
