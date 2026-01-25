# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Autentique::Models::Signature do
  describe '#initialize' do
    subject(:signature) { described_class.new(attributes) }

    let(:attributes) do
      {
        'public_id' => 'sig-123',
        'name' => 'John Doe',
        'email' => 'john@example.com',
        'created_at' => '2025-01-25T10:00:00Z',
        'action' => { 'name' => 'SIGN' },
        'link' => { 'short_link' => 'https://autentique.com.br/s/abc123' },
        'user' => { 'id' => 'user-123', 'name' => 'John Doe', 'email' => 'john@example.com' },
        'viewed' => { 'created_at' => '2025-01-25T10:05:00Z' },
        'signed' => { 'created_at' => '2025-01-25T10:10:00Z' },
        'rejected' => nil,
        'email_events' => {
          'sent' => true,
          'opened' => true,
          'delivered' => true,
          'refused' => false
        }
      }
    end

    it 'sets public_id attribute' do
      expect(signature.public_id).to eq('sig-123')
    end

    it 'sets name attribute' do
      expect(signature.name).to eq('John Doe')
    end

    it 'sets email attribute' do
      expect(signature.email).to eq('john@example.com')
    end

    it 'sets created_at attribute' do
      expect(signature.created_at).to eq('2025-01-25T10:00:00Z')
    end

    it 'sets action attribute' do
      expect(signature.action).to eq({ 'name' => 'SIGN' })
    end

    it 'sets link attribute' do
      expect(signature.link).to eq({ 'short_link' => 'https://autentique.com.br/s/abc123' })
    end

    it 'sets user attribute' do
      expect(signature.user).to eq(attributes['user'])
    end

    it 'sets viewed attribute' do
      expect(signature.viewed).to eq(attributes['viewed'])
    end

    it 'sets signed attribute' do
      expect(signature.signed).to eq(attributes['signed'])
    end

    it 'sets rejected attribute' do
      expect(signature.rejected).to be_nil
    end

    it 'sets email_events attribute' do
      expect(signature.email_events).to eq(attributes['email_events'])
    end
  end

  describe '#signed?' do
    context 'when signed attribute is present' do
      let(:attributes) do
        { 'email' => 'test@example.com', 'signed' => { 'created_at' => '2025-01-25T10:00:00Z' } }
      end

      it 'returns true' do
        signature = described_class.new(attributes)
        expect(signature.signed?).to be true
      end
    end

    context 'when signed attribute is nil' do
      let(:attributes) do
        { 'email' => 'test@example.com', 'signed' => nil }
      end

      it 'returns false' do
        signature = described_class.new(attributes)
        expect(signature.signed?).to be false
      end
    end

    context 'when signed attribute is empty hash' do
      let(:attributes) do
        { 'email' => 'test@example.com', 'signed' => {} }
      end

      it 'returns true' do
        signature = described_class.new(attributes)
        expect(signature.signed?).to be true
      end
    end
  end

  describe '#rejected?' do
    context 'when rejected attribute is present' do
      let(:attributes) do
        { 'email' => 'test@example.com', 'rejected' => { 'created_at' => '2025-01-25T10:00:00Z', 'reason' => 'Not interested' } }
      end

      it 'returns true' do
        signature = described_class.new(attributes)
        expect(signature.rejected?).to be true
      end
    end

    context 'when rejected attribute is nil' do
      let(:attributes) do
        { 'email' => 'test@example.com', 'rejected' => nil }
      end

      it 'returns false' do
        signature = described_class.new(attributes)
        expect(signature.rejected?).to be false
      end
    end

    context 'when rejected attribute is empty hash' do
      let(:attributes) do
        { 'email' => 'test@example.com', 'rejected' => {} }
      end

      it 'returns true' do
        signature = described_class.new(attributes)
        expect(signature.rejected?).to be true
      end
    end
  end

  describe '#pending?' do
    context 'when signature is not signed and not rejected' do
      let(:attributes) do
        { 'email' => 'test@example.com', 'signed' => nil, 'rejected' => nil }
      end

      it 'returns true' do
        signature = described_class.new(attributes)
        expect(signature.pending?).to be true
      end
    end

    context 'when signature is signed' do
      let(:attributes) do
        { 'email' => 'test@example.com', 'signed' => { 'created_at' => '2025-01-25T10:00:00Z' }, 'rejected' => nil }
      end

      it 'returns false' do
        signature = described_class.new(attributes)
        expect(signature.pending?).to be false
      end
    end

    context 'when signature is rejected' do
      let(:attributes) do
        { 'email' => 'test@example.com', 'signed' => nil, 'rejected' => { 'reason' => 'No' } }
      end

      it 'returns false' do
        signature = described_class.new(attributes)
        expect(signature.pending?).to be false
      end
    end

    context 'when signature is both signed and rejected' do
      let(:attributes) do
        { 'email' => 'test@example.com', 'signed' => { 'created_at' => '2025-01-25T10:00:00Z' }, 'rejected' => { 'reason' => 'No' } }
      end

      it 'returns false' do
        signature = described_class.new(attributes)
        expect(signature.pending?).to be false
      end
    end
  end

  describe '#short_link' do
    context 'when link attribute has short_link' do
      let(:attributes) do
        { 'email' => 'test@example.com', 'link' => { 'short_link' => 'https://autentique.com.br/s/abc123' } }
      end

      it 'returns the short link' do
        signature = described_class.new(attributes)
        expect(signature.short_link).to eq('https://autentique.com.br/s/abc123')
      end
    end

    context 'when link attribute is nil' do
      let(:attributes) do
        { 'email' => 'test@example.com', 'link' => nil }
      end

      it 'returns nil' do
        signature = described_class.new(attributes)
        expect(signature.short_link).to be_nil
      end
    end

    context 'when link attribute exists but short_link is missing' do
      let(:attributes) do
        { 'email' => 'test@example.com', 'link' => { 'other_field' => 'value' } }
      end

      it 'returns nil' do
        signature = described_class.new(attributes)
        expect(signature.short_link).to be_nil
      end
    end
  end
end
