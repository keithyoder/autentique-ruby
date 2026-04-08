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
      raise ArgumentError, 'Autentique API key is missing' if api_key.nil? || api_key.strip.empty?

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
      result = @graphql_client.query(query, variables: variables)

      if result.errors.any?
        messages = result.errors.map { |e| e['message'] }

        if messages.any? { |m| m =~ /authentication/i }
          raise AuthenticationError, 'Autentique API key is invalid or missing'
        end

        raise RateLimitError, 'Autentique API rate limit exceeded' if messages.any? { |m| m =~ /rate limit/i }

        raise QueryError.new('GraphQL query failed', messages)
      end

      result
    rescue Autentique::Error
      # Re-raise any Autentique errors untouched
      raise
    rescue StandardError => e
      # Wrap only unexpected low-level errors
      raise Error, "Unexpected error in Autentique client: #{e.message}"
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
      begin
        schema = GraphQL::Client.load_schema(@http_client)
      rescue StandardError => e
        raise Autentique::Error,
              'Unable to load GraphQL schema from Autentique API. ' \
              'Check your API key and network connectivity. ' \
              "Original error: #{e.message}"
      end

      client = GraphQL::Client.new(schema: schema, execute: @http_client)
      client.allow_dynamic_queries = true
      client
    end
  end
end
