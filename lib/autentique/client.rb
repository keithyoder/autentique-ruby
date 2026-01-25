# frozen_string_literal: true

require 'graphql/client'
require 'graphql/client/http'

module Autentique
  class Client
    API_ENDPOINT = 'https://api.autentique.com.br/v2/graphql'
    SANDBOX_ENDPOINT = 'https://api.autentique.com.br/v2/graphql' # Same endpoint, uses sandbox param

    attr_reader :api_key, :sandbox

    # Initialize a new Autentique client
    #
    # @param api_key [String] Your Autentique API key
    # @param sandbox [Boolean] Whether to use sandbox mode (default: false)
    def initialize(api_key:, sandbox: false)
      @api_key = api_key
      @sandbox = sandbox
      @http_client = build_http_client
      @graphql_client = build_graphql_client
    end

    # Access document-related operations
    #
    # @return [Autentique::Resources::Documents]
    def documents
      @documents ||= Resources::Documents.new(self)
    end

    # Access folder-related operations
    #
    # @return [Autentique::Resources::Folders]
    def folders
      @folders ||= Resources::Folders.new(self)
    end

    # Execute a GraphQL query
    #
    # @param query [GraphQL::Client::Query] The query to execute
    # @param variables [Hash] Query variables
    # @return [GraphQL::Client::Response]
    def query(query, variables: {})
      @graphql_client.query(query, variables: variables)
    end

    # Get the GraphQL client
    #
    # @return [GraphQL::Client]
    attr_reader :graphql_client

    private

    def build_http_client
      api_key = @api_key

      GraphQL::Client::HTTP.new(API_ENDPOINT) do
        define_method(:headers) do |_context|
          { 'Authorization' => "Bearer #{api_key}" }
        end
      end
    end

    def build_graphql_client
      schema = GraphQL::Client.load_schema(@http_client)
      GraphQL::Client.new(schema: schema, execute: @http_client)
    end
  end
end
