# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Autentique::Resources::Folders do
  include GraphQLHelpers

  # Use stub_const to avoid leaking a constant inside the block
  before do
    stub_const(
      'GraphQLFolder',
      Struct.new(:id, :name, :created_at) do
        def to_h
          {
            'id' => id,
            'name' => name,
            'created_at' => created_at
          }
        end
      end
    )
  end

  let(:api_key) { 'test_api_key' }
  let(:client) { Autentique::Client.new(api_key: api_key) }
  let(:folders) { described_class.new(client) }

  describe '#initialize' do
    it 'stores the client' do
      expect(folders.client).to eq(client)
    end
  end

  describe '#list' do
    let(:mock_response) do
      graphql_success(
        folders: [
          GraphQLFolder.new('folder-1', 'Contracts', '2025-01-20T10:00:00Z'),
          GraphQLFolder.new('folder-2', 'Invoices',  '2025-01-21T10:00:00Z')
        ]
      )
    end

    before do
      allow(client).to receive(:query).and_return(mock_response)
    end

    it 'returns an array of hashes' do
      expect(folders.list).to all(be_a(Hash))
    end
  end

  describe '#create' do
    let(:folder_name) { 'New Folder' }

    before do
      allow(client).to receive(:query)
        .and_return(
          graphql_success(
            create_folder: {
              'id' => 'uuid-123',
              'name' => folder_name,
              'created_at' => '2025-01-25T10:00:00Z'
            }
          )
        )
    end

    it 'returns a hash' do
      expect(folders.create(name: folder_name)).to be_a(Hash)
    end
  end

  describe '#delete' do
    before do
      allow(client).to receive(:query)
        .and_return(graphql_success(delete_folder: true))
    end

    it 'returns a boolean' do
      expect(folders.delete(id: 'folder-uuid')).to be(true)
    end
  end
end
