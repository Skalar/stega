# frozen_string_literal: true

module Stega
  module Encoder
    # Base-4 encoding uses 4 invisible characters
    BASE4_CHARS = [
      "\u200B", # ZERO WIDTH SPACE
      "\u200C", # ZERO WIDTH NON-JOINER
      "\u200D", # ZERO WIDTH JOINER
      "\uFEFF"  # ZERO WIDTH NO-BREAK SPACE (BOM)
    ].freeze

    # Prefix: 4 zero-width spaces used as a magic marker
    STEGA_PREFIX = (BASE4_CHARS[0] * 4).freeze

    # Encode a value into an invisible steganographic string (base-4 encoding).
    # Each byte is split into four 2-bit groups, each mapped to an invisible character.
    def self.encode(value)
      json = JSON.generate(value)
      bytes = json.encode(Encoding::UTF_8).bytes

      encoded = bytes.map do |byte|
        BASE4_CHARS[(byte >> 6) & 3] +
          BASE4_CHARS[(byte >> 4) & 3] +
          BASE4_CHARS[(byte >> 2) & 3] +
          BASE4_CHARS[byte & 3]
      end.join

      STEGA_PREFIX + encoded
    end
  end
end
