# frozen_string_literal: true

require 'net/http'
require 'json'
require 'mime/types'

require_relative 'documents/create'
require_relative 'documents/find'
require_relative 'documents/pending'
require_relative 'documents/list'
require_relative 'documents/delete'

module Autentique
  module Resources
    class Documents
      include Documents::Create
      include Documents::Find
      include Documents::Pending
      include Documents::List
      include Documents::Delete

      attr_reader :client

      def initialize(client)
        @client = client
      end

      private

      # Upload document using multipart/form-data
      def upload_document(file:, document:, signers:, organization_id: nil, folder_id: nil)
        uri = URI(Client::API_ENDPOINT)

        # Build GraphQL mutation
        mutation = build_create_mutation(organization_id, folder_id)

        # Build variables
        variables = {
          document: document.to_h,
          signers: signers.map(&:to_h),
          file: nil
        }

        # Prepare multipart request
        boundary = "----RubyAutentiqueGem#{Time.now.to_i}"
        body = build_multipart_body(
          mutation: mutation,
          variables: variables,
          file: file,
          boundary: boundary
        )

        # Make request
        http = build_http_client(uri)
        request = Net::HTTP::Post.new(uri.path)
        request['Authorization'] = "Bearer #{client.api_key}"
        request['Content-Type'] = "multipart/form-data; boundary=#{boundary}"
        request.body = body

        response = http.request(request)

        raise UploadError, "Upload failed: #{response.code} #{response.message}" unless response.is_a?(Net::HTTPSuccess)

        JSON.parse(response.body)
      end

      # Build the GraphQL mutation string for document creation
      def build_create_mutation(organization_id, folder_id) # rubocop:disable Metrics/MethodLength
        mutation = <<-GRAPHQL
          mutation CreateDocumentMutation(
            $document: DocumentInput!,
            $signers: [SignerInput!]!,
            $file: Upload!
          ) {
            createDocument(
              document: $document,
              signers: $signers,
              file: $file
        GRAPHQL

        mutation += ",\n      organization_id: #{organization_id}" if organization_id
        mutation += ",\n      folder_id: \"#{folder_id}\"" if folder_id

        mutation += <<-GRAPHQL
            ) {
              id
              name
              refusable
              sortable
              created_at
              signatures {
                public_id
                name
                email
                created_at
                action { name }
                link { short_link }
                user { id name email }
              }
            }
          }
        GRAPHQL

        mutation
      end

      # Build multipart/form-data body for file uploads
      def build_multipart_body(mutation:, variables:, file:, boundary:)
        parts = []
        parts.concat(build_operations_part(mutation, variables, boundary))
        parts.concat(build_map_part(boundary))
        parts.concat(build_file_part(file, boundary))
        parts << "--#{boundary}--\r\n"
        parts.join
      end

      def build_operations_part(mutation, variables, boundary)
        operations = { query: mutation, variables: variables }
        [
          "--#{boundary}\r\n",
          "Content-Disposition: form-data; name=\"operations\"\r\n\r\n",
          "#{operations.to_json}\r\n"
        ]
      end

      def build_map_part(boundary)
        map = { file: ['variables.file'] }
        [
          "--#{boundary}\r\n",
          "Content-Disposition: form-data; name=\"map\"\r\n\r\n",
          "#{map.to_json}\r\n"
        ]
      end

      def build_file_part(file, boundary)
        content, name, type = extract_file_info(file)
        [
          "--#{boundary}\r\n",
          "Content-Disposition: form-data; name=\"file\"; filename=\"#{name}\"\r\n",
          "Content-Type: #{type}\r\n\r\n",
          content,
          "\r\n"
        ]
      end

      def extract_file_info(file)
        if file.is_a?(String)
          [File.binread(file), File.basename(file),
           MIME::Types.type_for(file).first&.content_type || 'application/pdf']
        elsif file.is_a?(Hash)
          [file[:io].read, file[:name] || 'document.pdf', file[:mime_type] || 'application/pdf']
        else
          [file.read, 'document.pdf', 'application/pdf']
        end
      end

      def build_http_client(uri)
        Net::HTTP.new(uri.host, uri.port).tap do |http|
          http.use_ssl = true
        end
      end
    end
  end
end
