# frozen_string_literal: true

require "set"

module Stega
  module Sanity
    SKIP_KEYS = Set.new(%w[_id _type _ref _key _createdAt _updatedAt _rev _originalId _system slug]).freeze

    class << self
      def encode_source_map(result, source_map, config)
        validate_config!(config)
        return result unless source_map

        encode_into_result(result, source_map, config)
      end

      private

      def validate_config!(config)
        raise TypeError, "enabled must be true" unless config[:enabled]
        raise TypeError, "studio_url must be defined" unless config[:studio_url]
      end

      def encode_into_result(result, source_map, config)
        documents = source_map["documents"] || source_map[:documents] || []
        paths = source_map["paths"] || source_map[:paths] || []
        mappings = source_map["mappings"] || source_map[:mappings] || {}

        deep_transform(result, []) do |value, path|
          json_path = to_json_path(path)
          mapping, matched_path = resolve_mapping(json_path, mappings)

          next value unless mapping && value.is_a?(String)
          next value unless (mapping["type"] || mapping[:type] || "value") == "value"

          source = mapping["source"] || mapping[:source]
          next value unless source && (source["type"] || source[:type]) == "documentValue"

          doc_index = source["document"] || source[:document]
          path_index = source["path"] || source[:path]
          document = documents[doc_index]

          next value unless document

          context = {
            value: value,
            path: path,
            document: document
          }

          if config[:filter]
            next value unless config[:filter].call(context)
          end

          source_path = paths[path_index]
          full_path = resolve_full_source_path(source_path, json_path, matched_path)

          edit_url = create_edit_url(
            studio_url: config[:studio_url],
            document: document,
            path: full_path,
            omit_cross_dataset: config[:omit_cross_dataset_reference_data]
          )

          payload = { "origin" => "sanity.io", "href" => edit_url }
          Stega.combine(value, payload)
        end
      end

      def deep_transform(obj, path, &block)
        case obj
        when Hash
          obj.each_with_object({}) do |(key, value), result|
            if SKIP_KEYS.include?(key.to_s)
              result[key] = value
            else
              result[key] = deep_transform(value, path + [key], &block)
            end
          end
        when Array
          obj.each_with_index.map do |value, index|
            deep_transform(value, path + [index], &block)
          end
        else
          yield(obj, path)
        end
      end

      def create_edit_url(studio_url:, document:, path:, omit_cross_dataset: false)
        doc_id = document["_id"] || document[:_id]
        doc_type = document["_type"] || document[:_type]
        project_id = document["_projectId"] || document[:_projectId]
        dataset = document["_dataset"] || document[:_dataset]

        studio_path = json_path_to_studio_path(path)

        router_parts = [
          "mode=presentation",
          "id=#{doc_id}",
          "type=#{doc_type}",
          "path=#{URI.encode_www_form_component(studio_path)}"
        ]
        router_params = router_parts.join(";")

        search_hash = { baseUrl: studio_url, id: doc_id, type: doc_type, path: studio_path, perspective: "previewDrafts" }
        unless omit_cross_dataset
          search_hash[:projectId] = project_id if project_id
          search_hash[:dataset] = dataset if dataset
        end
        search_params = URI.encode_www_form(search_hash)

        "#{studio_url}/intent/edit/#{router_params}?#{search_params}"
      end

      def json_path_to_studio_path(json_path)
        rest = json_path.sub(/^\$/, "")
        segments = rest.scan(/\['([^']*)'\]|\[(\d+)\]/)

        result = +""
        segments.each_with_index do |(key, index), i|
          if index
            result << "[#{index}]"
          else
            result << "." if i > 0
            result << key
          end
        end
        result
      end

      def resolve_mapping(json_path, mappings)
        return [mappings[json_path], json_path] if mappings.key?(json_path)

        segments = parse_path_segments(json_path)
        (segments.length - 1).downto(1) do |i|
          candidate = "$" + segments[0...i].join
          return [mappings[candidate], candidate] if mappings.key?(candidate)
        end

        return [mappings["$"], "$"] if mappings.key?("$")

        nil
      end

      def parse_path_segments(json_path)
        json_path.sub(/^\$/, "").scan(/\['[^']*'\]|\[\d+\]/)
      end

      def resolve_full_source_path(source_path, result_path, matched_path)
        matched_segments = parse_path_segments(matched_path)
        result_segments = parse_path_segments(result_path)
        suffix_segments = result_segments[matched_segments.length..]

        if suffix_segments&.any?
          source_path + suffix_segments.join
        else
          source_path
        end
      end

      def to_json_path(path)
        json_path = path.map do |segment|
          if segment.is_a?(Integer) || segment =~ /^\d+$/
            "[#{segment}]"
          else
            "['#{segment}']"
          end
        end.join("")
        "$#{json_path}"
      end
    end
  end
end
