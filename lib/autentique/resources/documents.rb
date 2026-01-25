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
      def upload_document(file:, document:, signers:, organization_id: nil, folder_id: nil) # rubocop:disable Metrics/AbcSize
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
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

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

        # Operations part
        operations = { query: mutation, variables: variables }
        parts << "--#{boundary}\r\n"
        parts << "Content-Disposition: form-data; name=\"operations\"\r\n\r\n"
        parts << "#{operations.to_json}\r\n"

        # Map part
        map = { file: ['variables.file'] }
        parts << "--#{boundary}\r\n"
        parts << "Content-Disposition: form-data; name=\"map\"\r\n\r\n"
        parts << "#{map.to_json}\r\n"

        # File part
        file_path = file.is_a?(String) ? file : file.path
        file_content = File.binread(file_path)
        file_name = File.basename(file_path)
        mime_type = MIME::Types.type_for(file_path).first&.content_type || 'application/octet-stream'

        parts << "--#{boundary}\r\n"
        parts << "Content-Disposition: form-data; name=\"file\"; filename=\"#{file_name}\"\r\n"
        parts << "Content-Type: #{mime_type}\r\n\r\n"
        parts << file_content
        parts << "\r\n"

        # Close boundary
        parts << "--#{boundary}--\r\n"

        parts.join
      end
    end
  end
end
