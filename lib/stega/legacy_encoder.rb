# frozen_string_literal: true

module Stega
  module LegacyEncoder
    # Unicode zero-width and invisible characters used for hex encoding
    HEX_CHAR_MAP = {
      "0" => 8203,   # ZERO WIDTH SPACE
      "1" => 8204,   # ZERO WIDTH NON-JOINER
      "2" => 8205,   # ZERO WIDTH JOINER
      "3" => 8290,   # INVISIBLE TIMES
      "4" => 8291,   # INVISIBLE SEPARATOR
      "5" => 8288,   # WORD JOINER
      "6" => 65279,  # ZERO WIDTH NO-BREAK SPACE (BOM)
      "7" => 8289,   # INVISIBLE PLUS
      "8" => 119_155, # MUSICAL SYMBOL BEGIN BEAM
      "9" => 119_156, # MUSICAL SYMBOL END BEAM
      "a" => 119_157, # MUSICAL SYMBOL BEGIN TIE
      "b" => 119_158, # MUSICAL SYMBOL END TIE
      "c" => 119_159, # MUSICAL SYMBOL BEGIN SLUR
      "d" => 119_160, # MUSICAL SYMBOL END SLUR
      "e" => 119_161, # MUSICAL SYMBOL BEGIN PHRASE
      "f" => 119_162  # MUSICAL SYMBOL END PHRASE
    }.freeze

    # Legacy encoding: each ASCII character is encoded as two hex digits,
    # each mapped to an invisible Unicode character.
    def self.legacy_encode(value)
      json = JSON.generate(value)

      json.chars.map do |char|
        code = char.ord
        if code > 255
          raise ArgumentError,
            "Only ASCII edit info can be encoded. Error attempting to encode #{json} on character #{char} (#{code})"
        end

        hex = code.to_s(16).rjust(2, "0")
        hex.chars.map { |hex_digit| [HEX_CHAR_MAP[hex_digit]].pack("U") }.join
      end.join
    end
  end
end
