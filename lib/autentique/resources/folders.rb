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
      def list
        query = client.graphql_client.parse <<-GRAPHQL
          query {
            folders {
              id
              name
              created_at
            }
          }
        GRAPHQL

        result = client.query(query)
        raise QueryError.new('Query failed', result.errors.messages) if result.errors.any?

        result.data.folders.map(&:to_h)
      end

      # Create a new folder
      #
      # @param name [String] The folder name
      # @return [Hash]
      def create(name:)
        query = client.graphql_client.parse <<-GRAPHQL
          mutation($name: String!) {
            createFolder(name: $name) {
              id
              name
              created_at
            }
          }
        GRAPHQL

        result = client.query(query, variables: { name: name })
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
