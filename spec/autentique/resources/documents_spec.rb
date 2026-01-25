# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Autentique::Resources::Documents do
  include GraphQLHelpers

  let(:api_key) { 'test_api_key' }
  let(:client) { Autentique::Client.new(api_key: api_key, sandbox: true) }
  let(:documents) { described_class.new(client) }

  before do
    allow(client).to receive(:query)
  end

  describe '#initialize' do
    it 'stores the client' do
      expect(documents.client).to eq(client)
    end
  end

  describe '#find' do
    let(:document_id) { 'doc-uuid-123' }

    let(:document_payload) do
      {
        'id' => document_id,
        'name' => 'Test Document',
        'refusable' => true,
        'sortable' => false,
        'created_at' => '2025-01-25T10:00:00Z',
        'files' => {
          'original' => 'https://example.com/original.pdf',
          'signed' => 'https://example.com/signed.pdf'
        },
        'signatures' => [
          {
            'public_id' => 'sig-1',
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'created_at' => '2025-01-25T10:00:00Z',
            'action' => { 'name' => 'SIGN' },
            'link' => { 'short_link' => 'https://autentique.com.br/s/abc' }
          }
        ]
      }
    end

    before do
      allow(client).to receive(:query)
        .and_return(graphql_success(document: document_payload))
    end

    it 'executes GraphQL query with document ID' do
      documents.find(document_id)

      expect(client).to have_received(:query)
        .with(anything, variables: { id: document_id })
    end

    it 'returns a Document model' do
      expect(documents.find(document_id))
        .to be_a(Autentique::Models::Document)
    end

    it 'maps attributes correctly' do
      result = documents.find(document_id)

      expect(result.id).to eq(document_id)
      expect(result.name).to eq('Test Document')
      expect(result.refusable).to be(true)
      expect(result.sortable).to be(false)
    end

    it 'parses signatures' do
      signature = documents.find(document_id).signatures.first

      expect(signature)
        .to be_a(Autentique::Models::Signature)
      expect(signature.email)
        .to eq('john@example.com')
    end

    context 'when document is not found' do
      before do
        allow(client).to receive(:query)
          .and_return(graphql_success(document: nil))
      end

      it 'raises NotFoundError' do
        expect { documents.find(document_id) }
          .to raise_error(Autentique::NotFoundError)
      end
    end

    context 'when GraphQL query fails' do
      before do
        allow(client).to receive(:query)
          .and_return(graphql_error('Query failed'))
      end

      it 'raises QueryError' do
        expect { documents.find(document_id) }
          .to raise_error(Autentique::QueryError)
      end
    end
  end

  describe '#pending' do
    let(:documents_payload) do
      GraphQLDocumentsData.new(
        [
          { 'id' => 'doc-1', 'name' => 'Document 1', 'created_at' => '2025-01-25T10:00:00Z', 'signatures' => [] },
          { 'id' => 'doc-2', 'name' => 'Document 2', 'created_at' => '2025-01-25T11:00:00Z', 'signatures' => [] }
        ]
      )
    end

    before do
      allow(client).to receive(:query)
        .and_return(graphql_success(documents: documents_payload))
    end

    it 'uses default pagination' do
      documents.pending

      expect(client).to have_received(:query)
        .with(anything, variables: { limit: 60, page: 1 })
    end

    it 'accepts custom limit' do
      documents.pending(limit: 20)

      expect(client).to have_received(:query)
        .with(anything, variables: { limit: 20, page: 1 })
    end

    it 'returns Document models' do
      expect(documents.pending)
        .to all(be_a(Autentique::Models::Document))
    end

    context 'when no documents exist' do
      before do
        allow(client).to receive(:query)
          .and_return(graphql_success(documents: GraphQLDocumentsData.new([])))
      end

      it 'returns empty array' do
        expect(documents.pending).to eq([])
      end
    end

    context 'when query fails' do
      before do
        allow(client).to receive(:query)
          .and_return(graphql_error('Query failed'))
      end

      it 'raises QueryError' do
        expect { documents.pending }
          .to raise_error(Autentique::QueryError)
      end
    end
  end

  describe '#list' do
    let(:documents_payload) do
      GraphQLDocumentsData.new(
        [{ 'id' => 'doc-1', 'name' => 'Document 1', 'created_at' => '2025-01-25T10:00:00Z', 'signatures' => [] }]
      )
    end

    before do
      allow(client).to receive(:query)
        .and_return(graphql_success(documents: documents_payload))
    end

    it 'lists documents without status filter' do
      documents.list

      expect(client).to have_received(:query)
        .with(anything, variables: { limit: 60, page: 1 })
    end

    it 'accepts status filter' do
      documents.list(status: 'SIGNED')

      expect(client).to have_received(:query)
        .with(anything, variables: { status: 'SIGNED', limit: 60, page: 1 })
    end
  end

  describe '#delete' do
    let(:document_id) { 'doc-uuid-123' }

    before do
      allow(client).to receive(:query)
        .and_return(graphql_success(delete_document: true))
    end

    it 'returns boolean' do
      expect(documents.delete(document_id)).to be(true)
    end
  end
end
