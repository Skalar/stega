# frozen_string_literal: true

require "open3"
require "json"

module Stega
  module JsBridge
    VENDOR_JS = File.expand_path("../../vendor/js/vercel-stega.js", __dir__)

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

      def sanity_encode_source_map(result, source_map, config)
        js_config = convert_config_to_js(config)
        script = <<~JS
          const { stegaEncodeSourceMap } = require('@sanity/client/stega');
          const result = #{JSON.generate(result)};
          const sourceMap = #{JSON.generate(source_map)};
          const config = #{JSON.generate(js_config)};
          const encoded = stegaEncodeSourceMap(result, sourceMap, config);
          console.log(JSON.stringify(encoded));
        JS
        stdout, stderr, status = Open3.capture3("node", "-e", script)
        raise "Node.js error: #{stderr}\n#{stdout}" unless status.success?
        JSON.parse(stdout.strip)
      end

      private

      def convert_config_to_js(config)
        js_config = {}
        js_config["enabled"] = config[:enabled] if config.key?(:enabled)
        js_config["studioUrl"] = config[:studio_url] if config.key?(:studio_url)
        if config.key?(:omit_cross_dataset_reference_data)
          js_config["omitCrossDatasetReferenceData"] = config[:omit_cross_dataset_reference_data]
        end
        js_config
      end

      def run_js(fn, arg)
        script = <<~JS
          const stega = require(#{VENDOR_JS.to_json});
          const result = stega.#{fn}(#{JSON.generate(arg)});
          console.log(JSON.stringify(result));
        JS
        stdout, stderr, status = Open3.capture3("node", "-e", script)
        raise "Node.js error: #{stderr}\n#{stdout}" unless status.success?
        JSON.parse(stdout.strip)
      end
    end
  end
end
