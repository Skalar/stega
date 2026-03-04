# frozen_string_literal: true

module Stega
  module Sanity
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
          mapping = mappings[json_path]

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

          edit_url = create_edit_url(
            studio_url: config[:studio_url],
            document: document,
            path: paths[path_index],
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
            result[key] = deep_transform(value, path + [key], &block)
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
