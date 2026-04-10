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

  describe '#create' do
    let(:document_attrs) { { name: 'Test Contract' } }
    let(:signers) { [{ email: 'signer@example.com', action: 'SIGN' }] }
    let(:mock_http) { instance_double(Net::HTTP) }
    let(:success_body) do
      {
        'data' => {
          'createDocument' => {
            'id' => 'doc-123',
            'name' => 'Test Contract',
            'refusable' => false,
            'sortable' => false,
            'created_at' => '2025-01-25T10:00:00Z',
            'signatures' => []
          }
        }
      }.to_json
    end
    let(:success_response) do
      instance_double(Net::HTTPSuccess, is_a?: true, body: success_body)
    end

    before do
      allow(documents).to receive(:build_http_client).and_return(mock_http)
      allow(mock_http).to receive(:request).and_return(success_response)
    end

    context 'with a file path' do
      let(:file_path) { '/tmp/test.pdf' }

      before do
        allow(File).to receive_messages(
          binread: '%PDF binary content',
          basename: 'test.pdf'
        )
      end

      it 'returns a Document model' do
        result = documents.create(file: file_path, document: document_attrs, signers: signers)
        expect(result).to be_a(Autentique::Models::Document)
      end

      it 'sets the document name' do
        result = documents.create(file: file_path, document: document_attrs, signers: signers)
        expect(result.name).to eq('Test Contract')
      end
    end

    context 'with a Hash containing an IO object' do
      let(:file) { { io: StringIO.new('%PDF binary content'), name: 'contract.pdf', mime_type: 'application/pdf' } }

      it 'returns a Document model' do
        result = documents.create(file: file, document: document_attrs, signers: signers)
        expect(result).to be_a(Autentique::Models::Document)
      end
    end

    context 'with a bare IO object' do
      let(:file) { StringIO.new('%PDF binary content') }

      it 'returns a Document model' do
        result = documents.create(file: file, document: document_attrs, signers: signers)
        expect(result).to be_a(Autentique::Models::Document)
      end
    end

    context 'when upload fails' do
      let(:error_response) do
        instance_double(Net::HTTPUnauthorized, is_a?: false, code: '401', message: 'Unauthorized')
      end

      before do
        allow(mock_http).to receive(:request).and_return(error_response)
        allow(File).to receive_messages(
          binread: '%PDF binary content',
          basename: 'test.pdf'
        )
      end

      it 'raises UploadError' do
        expect do
          documents.create(file: '/tmp/test.pdf', document: document_attrs, signers: signers)
        end.to raise_error(Autentique::UploadError)
      end
    end
  end

  describe '#build_http_client' do
    it 'returns a Net::HTTP instance with SSL enabled' do
      uri = URI('https://api.autentique.com.br/v2/graphql')
      http = documents.send(:build_http_client, uri)

      expect(http).to be_a(Net::HTTP)
      expect(http.use_ssl?).to be(true)
    end
  end

  describe '#pending' do
    let(:documents_payload) do
      GraphQLDocumentsData.new(
        2,
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

    it 'returns a hash with documents and total' do
      result = documents.pending
      expect(result).to include(:documents, :total)
      expect(result[:documents]).to all(be_a(Autentique::Models::Document))
      expect(result[:total]).to be_a(Integer)
    end

    context 'when no documents exist' do
      before do
        allow(client).to receive(:query)
          .and_return(graphql_success(documents: GraphQLDocumentsData.new(0, [])))
      end

      it 'returns empty results' do
        result = documents.pending
        expect(result[:documents]).to eq([])
        expect(result[:total]).to eq(0)
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
        1,
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

  describe '#reject' do
    let(:document_id) { 'doc-uuid-123' }

    context 'without a reason' do
      before do
        allow(client).to receive(:query)
          .and_return(graphql_success(reject_document: true))
      end

      it 'returns true' do
        expect(documents.reject(document_id)).to be(true)
      end

      it 'passes only the id variable' do
        documents.reject(document_id)
        expect(client).to have_received(:query)
          .with(anything, variables: { id: document_id })
      end
    end

    context 'with a reason' do
      before do
        allow(client).to receive(:query)
          .and_return(graphql_success(reject_document: true))
      end

      it 'returns true' do
        expect(documents.reject(document_id, reason: 'Contrato cancelado')).to be(true)
      end

      it 'passes id and reason variables' do
        documents.reject(document_id, reason: 'Contrato cancelado')
        expect(client).to have_received(:query)
          .with(anything, variables: { id: document_id, reason: 'Contrato cancelado' })
      end
    end

    context 'when query fails' do
      before do
        allow(client).to receive(:query)
          .and_return(graphql_error('Query failed'))
      end

      it 'raises QueryError' do
        expect { documents.reject(document_id) }
          .to raise_error(Autentique::QueryError)
      end
    end
  end
end
