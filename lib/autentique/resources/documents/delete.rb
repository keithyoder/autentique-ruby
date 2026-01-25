# frozen_string_literal: true

module Autentique
  module Resources
    class Documents
      module Delete
        # Delete a document
        #
        # @param id [String] The document ID (UUID)
        # @return [Boolean]
        def delete(id)
          query = client.graphql_client.parse <<-GRAPHQL
            mutation($id: UUID!) {
              deleteDocument(id: $id)
            }
          GRAPHQL

          result = client.query(query, variables: { id: id })
          raise QueryError.new('Query failed', result.errors.messages) if result.errors.any?

          result.data.delete_document
        end
      end
    end
  end
end
