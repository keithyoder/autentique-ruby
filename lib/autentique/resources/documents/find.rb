# frozen_string_literal: true

module Autentique
  module Resources
    class Documents
      module Find
        def find(id) # rubocop:disable Metrics/MethodLength
          query = client.graphql_client.parse <<-GRAPHQL
          query($id: UUID!) {
            document(id: $id) {
              id
              name
              refusable
              sortable
              created_at
              files { original signed }
              signatures {
                public_id
                name
                email
                created_at
                action { name }
                link { short_link }
                user { id name email }
                viewed { created_at }
                signed { created_at }
                rejected { created_at reason }
                email_events { sent opened delivered refused reason }
              }
            }
          }
          GRAPHQL

          result = client.query(query, variables: { id: id })
          raise QueryError.new('Query failed', result.errors.messages) if result.errors.any?

          document_data = result.data.document
          raise NotFoundError, "Document with ID #{id} not found" if document_data.nil?

          Models::Document.new(document_data.to_h)
        end
      end
    end
  end
end
