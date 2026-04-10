# frozen_string_literal: true

module Autentique
  module Resources
    class Documents
      module Reject
        def reject(id, reason: nil)
          query = client.graphql_client.parse <<~GRAPHQL
            mutation($id: UUID!, $reason: String) {
              rejectDocument(id: $id, reason: $reason)
            }
          GRAPHQL

          variables = { id: id }
          variables[:reason] = reason if reason

          result = client.query(query, variables: variables)
          raise QueryError.new('Query failed', result.errors.messages) if result.errors.any?

          result.data.reject_document
        end
      end
    end
  end
end
