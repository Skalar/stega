# frozen_string_literal: true

require "json"
require "uri"
require "date"
require "open3"

require "stega/version"
require "stega/encoder"
require "stega/legacy_encoder"
require "stega/decoder"
require "stega/js_bridge"
require "stega/sanity"

module Stega
  # Regex to match encoded strings
  REGEX = Decoder::REGEX

  class << self
    # Encode a value into an invisible steganographic string (base-4 encoding)
    def encode(value)
      Encoder.encode(value)
    end

    # Decode the first steganographic payload from a string
    def decode(str)
      Decoder.decode(str)
    end

    # Decode all steganographic payloads from a string
    def decode_all(str)
      Decoder.decode_all(str)
    end

    # Legacy encoding using hex pairs
    def legacy_encode(value)
      LegacyEncoder.legacy_encode(value)
    end

    # Combine a visible string with invisible encoded data
    # mode can be :auto (default), :skip (true), or false
    def combine(visible, data, mode = :auto)
      skip = case mode
             when true, :skip
               true
             when :auto
               date_like?(visible) || url?(visible)
             else
               false
             end

      return visible if skip

      "#{visible}#{encode(data)}"
    end

    # Split a string into its visible content and the encoded (invisible) portion
    def split(str)
      match = str.match(REGEX)
      {
        cleaned: str.gsub(REGEX, ""),
        encoded: match ? match[0] : ""
      }
    end

    # Deep-clean an object by removing all steganographic data
    def clean(value)
      return value unless value

      JSON.parse(split(JSON.generate(value))[:cleaned])
    end

    private

    # Check if a string looks like a date
    def date_like?(str)
      return false if str.nil? || str.empty?

      # Not a date if it's a plain number
      return false if numeric?(str)

      # If it contains letters but doesn't match date pattern, not a date
      if str.match?(/[a-z]/i) &&
         !str.match?(/\d+(?:[-:\/]\d+){2}(?:T\d+(?:[-:\/]\d+){1,2}(\.\d+)?Z?)?/)
        return false
      end

      # Try to parse as date
      begin
        Date.parse(str)
        true
      rescue ArgumentError, TypeError
        false
      end
    end

    # Check if a string is a valid URL
    def url?(str)
      return false if str.nil? || str.empty?

      begin
        if str.start_with?("/")
          URI.parse("https://acme.com#{str}")
        else
          uri = URI.parse(str)
          # Must have a scheme to be a valid URL
          return false unless uri.scheme

          uri
        end
        true
      rescue URI::InvalidURIError
        false
      end
    end

    # Check if a string is numeric
    def numeric?(str)
      Float(str)
      true
    rescue ArgumentError, TypeError
      false
    end
  end
end
