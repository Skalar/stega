# frozen_string_literal: true

module Stega
  module Decoder
    # Reverse lookup: invisible character → base-4 digit
    BASE4_REVERSE_MAP = Encoder::BASE4_CHARS.each_with_index.to_h { |char, idx| [char, idx] }.freeze

    # Reverse lookup: invisible codepoint → hex digit
    HEX_REVERSE_MAP = LegacyEncoder::HEX_CHAR_MAP.to_h { |hex_digit, codepoint| [codepoint, hex_digit] }.freeze

    # Regex character class matching all invisible stega characters
    STEGA_CHAR_CLASS = LegacyEncoder::HEX_CHAR_MAP.values.map { |cp| format("\\u{%x}", cp) }.join

    # Regex to match encoded strings (4+ invisible characters)
    REGEX = Regexp.new("[#{STEGA_CHAR_CLASS}]{4,}")

    NULL_CHAR = "\x00"

    # Decode the first steganographic payload from a string.
    def self.decode(str)
      match = str.match(REGEX)
      return nil unless match

      decode_payload(match[0], first_only: true).first
    end

    # Decode all steganographic payloads from a string.
    def self.decode_all(str)
      matches = str.scan(REGEX)
      return nil if matches.empty?

      matches.flat_map { |m| decode_payload(m) }
    end

    # Decode an invisible-character payload back into JSON value(s).
    # Detects whether it's new (base-4 with prefix) or legacy (hex-pair) encoding.
    def self.decode_payload(encoded, first_only: false)
      chars = encoded.chars

      # If even length but not divisible by 4 or missing prefix → legacy encoding
      if chars.length.even?
        if (chars.length % 4 != 0) || !encoded.start_with?(Encoder::STEGA_PREFIX)
          return decode_legacy_payload(chars, first_only)
        end
      else
        raise ArgumentError, "Encoded data has invalid length"
      end

      # New base-4 encoding: skip 4-char prefix
      data_chars = chars[4..]
      bytes = Array.new(data_chars.length / 4)

      bytes.length.times do |i|
        bytes[i] = (BASE4_REVERSE_MAP[data_chars[i * 4]] << 6) |
                   (BASE4_REVERSE_MAP[data_chars[i * 4 + 1]] << 4) |
                   (BASE4_REVERSE_MAP[data_chars[i * 4 + 2]] << 2) |
                   BASE4_REVERSE_MAP[data_chars[i * 4 + 3]]
      end

      decoded = bytes.pack("C*").force_encoding(Encoding::UTF_8)

      if first_only
        null_index = decoded.index(NULL_CHAR) || decoded.length
        return [JSON.parse(decoded[0...null_index])]
      end

      decoded.split(NULL_CHAR).reject(&:empty?).map { |segment| JSON.parse(segment) }
    end

    # Decode legacy hex-pair encoded payload.
    # Each pair of invisible characters represents one hex byte → one ASCII character.
    def self.decode_legacy_payload(chars, first_only)
      ascii_chars = []

      (chars.length / 2).times do |i|
        idx = (chars.length / 2) - 1 - i
        hex_str = HEX_REVERSE_MAP[chars[idx * 2].ord].to_s +
                  HEX_REVERSE_MAP[chars[idx * 2 + 1].ord].to_s
        ascii_chars.unshift(hex_str.to_i(16).chr)
      end

      results = []
      queue = [ascii_chars.join]
      max_retries = 10

      # Try to parse concatenated JSON values by splitting at parse error positions
      until queue.empty?
        str = queue.shift
        begin
          results << JSON.parse(str)
          return results if first_only
        rescue JSON::ParserError => e
          max_retries -= 1
          raise e if max_retries <= 0

          # Extract position from error message
          pos_match = e.message.match(/at (?:line \d+, )?column (\d+)/)
          error_pos = pos_match ? pos_match[1].to_i : nil

          # Ruby's JSON parser reports 1-based column, convert to 0-based index
          # Also try to find the actual position by looking for unexpected token position
          if error_pos.nil? || error_pos == 0
            # Try alternate pattern
            pos_match = e.message.match(/position (\d+)/)
            error_pos = pos_match ? pos_match[1].to_i : nil
          end

          raise e if error_pos.nil? || error_pos == 0

          # For 1-based column, subtract 1 for 0-based index
          error_pos -= 1 if error_pos > 0
          queue.unshift(str[0...error_pos], str[error_pos..])
        end
      end

      results
    end
  end
end
