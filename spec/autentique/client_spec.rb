# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Autentique::Client do
  let(:api_key) { 'test_api_key_123' }

  describe '#initialize' do
    context 'with required parameters' do
      subject(:client) { described_class.new(api_key: api_key) }

      it 'sets the api_key' do
        expect(client.api_key).to eq(api_key)
      end

      it 'defaults sandbox to false' do
        expect(client.sandbox).to be false
      end

      it 'initializes documents resource' do
        expect(client.documents).to be_a(Autentique::Resources::Documents)
      end

      it 'initializes folders resource' do
        expect(client.folders).to be_a(Autentique::Resources::Folders)
      end

      it 'initializes graphql client' do
        expect(client.graphql_client).to be_a(GraphQL::Client)
      end
    end

    context 'with sandbox mode enabled' do
      subject(:client) { described_class.new(api_key: api_key, sandbox: true) }

      it 'sets sandbox to true' do
        expect(client.sandbox).to be true
      end
    end
  end

  describe '#documents' do
    subject(:client) { described_class.new(api_key: api_key) }

    it 'returns a Documents resource' do
      expect(client.documents).to be_a(Autentique::Resources::Documents)
    end

    it 'passes the client to the Documents resource' do
      documents = client.documents
      expect(documents.client).to eq(client)
    end

    it 'memoizes the documents resource' do
      documents1 = client.documents
      documents2 = client.documents
      expect(documents1).to be(documents2)
    end
  end

  describe '#folders' do
    subject(:client) { described_class.new(api_key: api_key) }

    it 'returns a Folders resource' do
      expect(client.folders).to be_a(Autentique::Resources::Folders)
    end

    it 'passes the client to the Folders resource' do
      folders = client.folders
      expect(folders.client).to eq(client)
    end

    it 'memoizes the folders resource' do
      folders1 = client.folders
      folders2 = client.folders
      expect(folders1).to be(folders2)
    end
  end

  describe '#query' do
    subject(:client) { described_class.new(api_key: api_key) }

    let(:mock_query) { instance_double(GraphQL::Query) }
    let(:variables) { { id: 'test-123' } }
    let(:mock_response) { instance_double(GraphQL::Client::Response, errors: []) }

    # For errors
    let(:auth_error_response) { instance_double(GraphQL::Client::Response, errors: [{ 'message' => 'Authentication failed' }]) }
    let(:rate_limit_response) { instance_double(GraphQL::Client::Response, errors: [{ 'message' => 'Rate limit exceeded' }]) }
    let(:other_error_response) { instance_double(GraphQL::Client::Response, errors: [{ 'message' => 'Some other error' }]) }

    before do
      allow(client.graphql_client).to receive(:query)
        .with(mock_query, variables: variables)
        .and_return(mock_response)
    end

    it 'delegates to the graphql_client' do
      result = client.query(mock_query, variables: variables)
      expect(result).to eq(mock_response)
    end

    it 'accepts query without variables' do
      allow(client.graphql_client).to receive(:query)
        .with(mock_query, variables: {})
        .and_return(mock_response)

      result = client.query(mock_query)
      expect(result).to eq(mock_response)
    end

    context 'when GraphQL returns authentication errors' do
      let(:auth_error_response) { instance_double(GraphQL::Client::Response, errors: [{ 'message' => 'Authentication failed' }]) }

      before do
        allow(client.graphql_client).to receive(:query)
          .with(mock_query, variables: variables)
          .and_return(auth_error_response)
      end

      it 'raises Autentique::AuthenticationError' do
        expect do
          client.query(mock_query, variables: variables)
        end.to raise_error(Autentique::AuthenticationError)
      end
    end

    context 'when GraphQL returns rate limit errors' do
      let(:rate_limit_response) { instance_double(GraphQL::Client::Response, errors: [{ 'message' => 'Rate limit exceeded' }]) }

      before do
        allow(client.graphql_client).to receive(:query)
          .with(mock_query, variables: variables)
          .and_return(rate_limit_response)
      end

      it 'raises Autentique::RateLimitError' do
        expect do
          client.query(mock_query, variables: variables)
        end.to raise_error(Autentique::RateLimitError, /rate limit/i)
      end
    end

    context 'when GraphQL returns other errors' do
      let(:other_error_response) { instance_double(GraphQL::Client::Response, errors: [{ 'message' => 'Some other error' }]) }

      before do
        allow(client.graphql_client).to receive(:query)
          .with(mock_query, variables: variables)
          .and_return(other_error_response)
      end

      it 'raises Autentique::QueryError' do
        expect do
          client.query(mock_query, variables: variables)
        end.to raise_error(Autentique::QueryError)
      end

      it 'includes error messages in the QueryError' do
        error = nil
        begin
          client.query(mock_query, variables: variables)
        rescue Autentique::QueryError => e
          error = e
        end
        expect(error.errors).to eq(['Some other error'])
      end
    end

    context 'when an unexpected low-level error occurs' do
      before do
        allow(client.graphql_client).to receive(:query)
          .and_raise(SocketError, 'connection refused')
      end

      it 'wraps the error as Autentique::Error' do
        expect { client.query(mock_query, variables: variables) }
          .to raise_error(Autentique::Error, /Unexpected error.*connection refused/i)
      end
    end
  end

  describe '#build_http_client (headers)' do
    let(:client) { described_class.new(api_key: api_key) }

    it 'sets the Authorization header with the API key' do
      http_client = client.send(:build_http_client)
      headers = http_client.headers({})
      expect(headers['Authorization']).to eq("Bearer #{api_key}")
    end
  end

  describe '#build_graphql_client' do
    it 'raises Autentique::Error when schema cannot be loaded' do
      allow(GraphQL::Client).to receive(:load_schema).and_raise(StandardError, 'timeout')

      expect { described_class.new(api_key: api_key) }
        .to raise_error(Autentique::Error, /Unable to load GraphQL schema.*timeout/i)
    end
  end
end
