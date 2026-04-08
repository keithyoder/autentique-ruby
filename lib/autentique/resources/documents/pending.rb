# frozen_string_literal: true

module Autentique
  module Resources
    class Documents
      module Pending
        def self.pending_query(client)
          client.graphql_client.parse <<~GRAPHQL
            query($limit: Int!, $page: Int!) {
              documents(status: PENDING, limit: $limit, page: $page) {
                total
                data {
                  id
                  name
                  created_at
                  signatures {
                    public_id
                    name
                    email
                    user { id name email phone }
                    delivery_method
                    email_events { sent opened delivered refused reason }
                  }
                }
              }
            }
          GRAPHQL
        end

        def pending(limit: 60, page: 1)
          query = Pending.pending_query(client)
          result = client.query(query, variables: { limit: limit, page: page })
          raise QueryError.new('Query failed', result.errors.messages) if result.errors.any?

          result.data.documents&.data&.map { |doc| Models::Document.new(doc.to_h) } || []
        end
      end
    end
  end
end
