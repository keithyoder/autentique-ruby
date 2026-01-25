# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Autentique::Models::Document do
  describe '#initialize' do
    subject(:document) { described_class.new(attributes) }

    let(:attributes) do
      {
        'id' => 'doc-uuid-123',
        'name' => 'Test Document',
        'refusable' => true,
        'sortable' => false,
        'created_at' => '2025-01-25T10:00:00Z',
        'signatures' => [
          {
            'public_id' => 'sig-1',
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'created_at' => '2025-01-25T10:00:00Z',
            'action' => { 'name' => 'SIGN' },
            'link' => { 'short_link' => 'https://autentique.com.br/s/abc123' },
            'signed' => nil,
            'rejected' => nil
          }
        ],
        'files' => {
          'original' => 'https://example.com/original.pdf',
          'signed' => 'https://example.com/signed.pdf'
        }
      }
    end

    it 'sets id attribute' do
      expect(document.id).to eq('doc-uuid-123')
    end

    it 'sets name attribute' do
      expect(document.name).to eq('Test Document')
    end

    it 'sets refusable attribute' do
      expect(document.refusable).to be true
    end

    it 'sets sortable attribute' do
      expect(document.sortable).to be false
    end

    it 'sets created_at attribute' do
      expect(document.created_at).to eq('2025-01-25T10:00:00Z')
    end

    it 'sets files attribute' do
      expect(document.files).to eq(attributes['files'])
    end

    it 'parses signatures into Signature objects' do
      expect(document.signatures).to all(be_a(Autentique::Models::Signature))
    end

    it 'creates the correct number of signatures' do
      expect(document.signatures.size).to eq(1)
    end

    context 'when signatures are nil' do
      let(:attributes) { { 'id' => 'doc-123', 'signatures' => nil } }

      it 'returns empty array for signatures' do
        expect(document.signatures).to eq([])
      end
    end

    context 'when signatures are empty array' do
      let(:attributes) { { 'id' => 'doc-123', 'signatures' => [] } }

      it 'returns empty array for signatures' do
        expect(document.signatures).to eq([])
      end
    end
  end

  describe '#signed?' do
    let(:base_attributes) do
      {
        'id' => 'doc-123',
        'name' => 'Test Doc'
      }
    end

    context 'when all signatures are signed' do
      let(:attributes) do
        base_attributes.merge(
          'signatures' => [
            { 'email' => 'user1@example.com', 'signed' => { 'created_at' => '2025-01-25T10:00:00Z' } },
            { 'email' => 'user2@example.com', 'signed' => { 'created_at' => '2025-01-25T11:00:00Z' } }
          ]
        )
      end

      it 'returns true' do
        document = described_class.new(attributes)
        expect(document.signed?).to be true
      end
    end

    context 'when some signatures are not signed' do
      let(:attributes) do
        base_attributes.merge(
          'signatures' => [
            { 'email' => 'user1@example.com', 'signed' => { 'created_at' => '2025-01-25T10:00:00Z' } },
            { 'email' => 'user2@example.com', 'signed' => nil }
          ]
        )
      end

      it 'returns false' do
        document = described_class.new(attributes)
        expect(document.signed?).to be false
      end
    end

    context 'when no signatures exist' do
      let(:attributes) { base_attributes.merge('signatures' => []) }

      it 'returns true (vacuous truth)' do
        document = described_class.new(attributes)
        expect(document.signed?).to be true
      end
    end
  end

  describe '#pending?' do
    let(:base_attributes) { { 'id' => 'doc-123', 'name' => 'Test Doc' } }

    context 'when document is signed' do
      let(:attributes) do
        base_attributes.merge(
          'signatures' => [
            { 'email' => 'user@example.com', 'signed' => { 'created_at' => '2025-01-25T10:00:00Z' } }
          ]
        )
      end

      it 'returns false' do
        document = described_class.new(attributes)
        expect(document.pending?).to be false
      end
    end

    context 'when document is not signed' do
      let(:attributes) do
        base_attributes.merge(
          'signatures' => [
            { 'email' => 'user@example.com', 'signed' => nil }
          ]
        )
      end

      it 'returns true' do
        document = described_class.new(attributes)
        expect(document.pending?).to be true
      end
    end
  end

  describe '#rejected?' do
    let(:base_attributes) { { 'id' => 'doc-123', 'name' => 'Test Doc' } }

    context 'when at least one signature is rejected' do
      let(:attributes) do
        base_attributes.merge(
          'signatures' => [
            { 'email' => 'user1@example.com', 'signed' => nil, 'rejected' => nil },
            { 'email' => 'user2@example.com', 'signed' => nil, 'rejected' => { 'created_at' => '2025-01-25T10:00:00Z', 'reason' => 'Not interested' } }
          ]
        )
      end

      it 'returns true' do
        document = described_class.new(attributes)
        expect(document.rejected?).to be true
      end
    end

    context 'when no signatures are rejected' do
      let(:attributes) do
        base_attributes.merge(
          'signatures' => [
            { 'email' => 'user@example.com', 'signed' => nil, 'rejected' => nil }
          ]
        )
      end

      it 'returns false' do
        document = described_class.new(attributes)
        expect(document.rejected?).to be false
      end
    end
  end
end
