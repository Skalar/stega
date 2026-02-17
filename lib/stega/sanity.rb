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
        documents = source_map["documents"] || []
        paths = source_map["paths"] || []
        mappings = source_map["mappings"] || {}

        deep_transform(result, []) do |value, path|
          path_key = path.join(".")
          mapping = mappings[path_key]

          next value unless mapping && value.is_a?(String)

          source = mapping["source"]
          next value unless source

          doc_index = source["document"]
          path_index = source["path"]
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
            deep_transform(value, path + [index.to_s], &block)
          end
        else
          yield(obj, path)
        end
      end

      def create_edit_url(studio_url:, document:, path:, omit_cross_dataset: false)
        doc_id = document["_id"]
        doc_type = document["_type"]
        project_id = document["_projectId"]
        dataset = document["_dataset"]

        base = resolve_studio_base_route(studio_url)

        params_hash = { id: doc_id, type: doc_type, path: path }
        unless omit_cross_dataset
          params_hash[:projectId] = project_id if project_id
          params_hash[:dataset] = dataset if dataset
        end

        params = URI.encode_www_form(params_hash)
        "#{base[:base_url]}/intent/edit?#{params}"
      end

      def resolve_studio_base_route(studio_url)
        uri = URI.parse(studio_url)
        { base_url: "#{uri.scheme}://#{uri.host}" }
      end
    end
  end
end
