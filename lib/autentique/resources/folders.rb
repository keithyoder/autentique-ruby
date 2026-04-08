# frozen_string_literal: true

module Autentique
  module Resources
    class Folders
      attr_reader :client

      def initialize(client)
        @client = client
      end

      # List all folders
      #
      # @return [Array<Hash>]
      def list(limit: 30, page: 1)
        query = client.graphql_client.parse <<-GRAPHQL
          query($limit: Int!, $page: Int!) {
            folders(limit: $limit, page: $page) {
              total
              data {
                id
                name
                created_at
              }
            }
          }
        GRAPHQL

        result = client.query(query, variables: { limit: limit, page: page })
        raise QueryError.new('Query failed', result.errors.messages) if result.errors.any?

        result.data.folders.data.map(&:to_h)
      end

      # Create a new folder
      #
      # @param name [String] The folder name
      # @param parent_id [String, nil] The parent folder ID
      # @return [Hash]
      def create(name:, parent_id: nil)
        query = client.graphql_client.parse <<-GRAPHQL
          mutation($folder: FolderInput!, $parent_id: UUID) {
            createFolder(folder: $folder, parent_id: $parent_id) {
              id
              name
              created_at
            }
          }
        GRAPHQL

        variables = { folder: { name: name } }
        variables[:parent_id] = parent_id if parent_id

        result = client.query(query, variables: variables)
        raise QueryError.new('Query failed', result.errors.messages) if result.errors.any?

        result.data.create_folder.to_h
      end
      # Delete a folder
      #
      # @param id [String] The folder ID
      # @return [Boolean]
      def delete(id:)
        query = client.graphql_client.parse <<-GRAPHQL
          mutation($id: UUID!) {
            deleteFolder(id: $id)
          }
        GRAPHQL

        result = client.query(query, variables: { id: id })
        raise QueryError.new('Query failed', result.errors.messages) if result.errors.any?

        result.data.delete_folder
      end
    end
  end
end
