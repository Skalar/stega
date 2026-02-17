# frozen_string_literal: true

module Stega
  module Sanity
    class << self
      def encode_source_map(result, source_map, config)
        validate_config!(config)
        result
      end

      private

      def validate_config!(config)
        raise TypeError, "enabled must be true" unless config[:enabled]
      end
    end
  end
end
