# frozen_string_literal: true

module Autentique
  module Resources
    class Documents
      module List
        def list(status: nil, limit: 60, page: 1) # rubocop:disable Metrics/MethodLength
          query_string = if status
                           <<-GRAPHQL
          query($status: DocumentStatus, $limit: Int, $page: Int) {
            documents(status: $status, limit: $limit, page: $page) {
              total
              data { id name created_at signatures { public_id name email } }
            }
          }
                           GRAPHQL
                         else
                           <<-GRAPHQL
          query($limit: Int, $page: Int) {
            documents(limit: $limit, page: $page) {
              total
              data { id name created_at signatures { public_id name email } }
            }
          }
                           GRAPHQL
                         end

          query = client.graphql_client.parse(query_string)
          variables = { limit: limit, page: page }
          variables[:status] = status if status

          result = client.query(query, variables: variables)
          raise QueryError.new('Query failed', result.errors.messages) if result.errors.any?

          docs = result.data.documents&.data || []
          docs.map { |doc| Models::Document.new(doc.to_h) }
        end
      end
    end
  end
end
