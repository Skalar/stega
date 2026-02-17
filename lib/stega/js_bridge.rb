# frozen_string_literal: true

require "open3"
require "json"

module Stega
  module JsBridge
    VENDOR_JS = File.expand_path("../../../vendor/js/vercel-stega.js", __FILE__)

    class << self
      def encode(value)
        run_js("vercelStegaEncode", value)
      end

      def decode(str)
        run_js("vercelStegaDecode", str)
      end

      def legacy_encode(value)
        run_js("legacyStegaEncode", value)
      end

      private

      def run_js(fn, arg)
        script = <<~JS
          const stega = require(#{VENDOR_JS.to_json});
          const result = stega.#{fn}(#{JSON.generate(arg)});
          console.log(JSON.stringify(result));
        JS
        stdout, status = Open3.capture2("node", "-e", script)
        raise "Node.js error: #{stdout}" unless status.success?
        JSON.parse(stdout.strip)
      end
    end
  end
end
