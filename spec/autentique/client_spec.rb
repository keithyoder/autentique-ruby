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
    let(:mock_response) { instance_double(GraphQL::Client::Response) }

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
  end

  describe '#graphql_client' do
    subject(:client) { described_class.new(api_key: api_key) }

    it 'returns a GraphQL::Client instance' do
      expect(client.graphql_client).to be_a(GraphQL::Client)
    end

    it 'memoizes the graphql_client' do
      client1 = client.graphql_client
      client2 = client.graphql_client
      expect(client1).to be(client2)
    end
  end

  describe 'API endpoint constants' do
    it 'defines API_ENDPOINT' do
      expect(described_class::API_ENDPOINT).to eq('https://api.autentique.com.br/v2/graphql')
    end

    it 'defines SANDBOX_ENDPOINT' do
      expect(described_class::SANDBOX_ENDPOINT).to eq('https://api.autentique.com.br/v2/graphql')
    end
  end
end
