# frozen_string_literal: true

require 'spec_helper'
require 'openssl'

RSpec.describe Autentique::WebhookProcessor do
  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  # Builds a realistic webhook payload matching Autentique's format
  def json_body(event_type:, data: {}, previous_attributes: [], **extra)
    {
      'id' => 'MXwyMWZiY2VjOS1lMWI1LTRkY2EtYWZiYi0wMjIwNjFlOWVhODg=',
      'object' => 'webhook',
      'name' => 'test endpoint',
      'format' => 'json',
      'url' => 'https://example.com/webhooks',
      'event' => {
        'id' => '21fbcec9-e1b5-4dca-afbb-022061e9ea88',
        'object' => 'event',
        'organization' => 1,
        'type' => event_type,
        'data' => data,
        'previous_attributes' => previous_attributes,
        'created_at' => '2024-08-26T18:03:27.387179Z'
      }
    }.merge(extra).to_json
  end

  def hmac_signature(secret, payload_json)
    parsed = JSON.parse(payload_json)
    OpenSSL::HMAC.hexdigest('SHA256', secret, parsed.to_json)
  end

  def stub_secure_compare
    stub_const('ActiveSupport::SecurityUtils', Module.new do
      def self.secure_compare(a, b) # rubocop:disable Naming/MethodParameterName, Naming/PredicateMethod
        a == b
      end
    end)
  end

  def stub_secure_compare_raising
    stub_const('ActiveSupport::SecurityUtils', Module.new do
      def self.secure_compare(_a, _b) # rubocop:disable Naming/MethodParameterName
        raise 'comparison exploded'
      end
    end)
  end

  # ---------------------------------------------------------------------------
  # #initialize / payload parsing
  # ---------------------------------------------------------------------------
  describe '#initialize' do
    context 'with a valid JSON body' do
      subject(:processor) { described_class.new(json_body(event_type: 'document.finished', data: data)) }

      let(:data) { { 'id' => 'doc-123', 'name' => 'My Document' } }

      it 'parses the payload as a hash' do
        expect(processor.payload).to be_a(Hash)
      end

      it 'exposes the event_type' do
        expect(processor.event_type).to eq('document.finished')
      end

      it 'exposes the event object' do
        expect(processor.event['type']).to eq('document.finished')
      end

      it 'exposes event_data' do
        expect(processor.event_data).to eq(data)
      end
    end

    context 'with previous_attributes' do
      subject(:processor) do
        described_class.new(json_body(event_type: 'document.updated', previous_attributes: previous))
      end

      let(:previous) { { 'name' => 'Old Name' } }

      it 'exposes previous_attributes' do
        expect(processor.previous_attributes).to eq(previous)
      end
    end

    context 'with neither secret nor signature' do
      it 'does not raise on initialization' do
        expect { described_class.new(json_body(event_type: 'document.created')) }.not_to raise_error
      end
    end

    context 'with an invalid JSON body' do
      it 'raises ArgumentError' do
        expect { described_class.new('not-json') }
          .to raise_error(ArgumentError, /Invalid webhook payload/)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #valid_signature?
  # ---------------------------------------------------------------------------
  describe '#valid_signature?' do
    let(:secret) { 'whsec_test_secret' }
    let(:body)   { json_body(event_type: 'document.finished') }
    let(:valid_sig) { hmac_signature(secret, body) }

    context 'when no secret is configured' do
      subject(:processor) { described_class.new(body, signature: 'anything') }

      it 'returns true without checking the signature' do
        expect(processor.valid_signature?).to be(true)
      end
    end

    context 'with a valid HMAC-SHA256 signature' do
      subject(:processor) { described_class.new(body, secret: secret, signature: valid_sig) }

      before { stub_secure_compare }

      it 'returns true' do
        expect(processor.valid_signature?).to be(true)
      end
    end

    context 'with an invalid signature' do
      subject(:processor) { described_class.new(body, secret: secret, signature: 'bad_signature') }

      before { stub_secure_compare }

      it 'returns false' do
        expect(processor.valid_signature?).to be(false)
      end
    end

    context 'with a tampered body' do
      subject(:processor) do
        described_class.new(tampered_body, secret: secret, signature: valid_sig)
      end

      let(:tampered_body) { json_body(event_type: 'document.finished', injected: true) }

      before { stub_secure_compare }

      it 'returns false' do
        expect(processor.valid_signature?).to be(false)
      end
    end

    context 'when secure_compare raises an unexpected error' do
      subject(:processor) { described_class.new(body, secret: secret, signature: valid_sig) }

      before { stub_secure_compare_raising }

      it 'returns false and does not propagate the error' do
        expect(processor.valid_signature?).to be(false)
      end
    end

    context 'without ActiveSupport (plain string comparison)' do
      subject(:processor) { described_class.new(body, secret: secret, signature: valid_sig) }

      it 'returns true with a valid signature' do
        expect(processor.valid_signature?).to be(true)
      end

      it 'returns false with an invalid signature' do
        processor = described_class.new(body, secret: secret, signature: 'bad_sig')
        expect(processor.valid_signature?).to be(false)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #process
  # ---------------------------------------------------------------------------
  describe '#process' do
    subject(:processor) { described_class.new(body) }

    let(:data) { { 'id' => 'doc-789', 'name' => 'My Document' } }
    let(:body) { json_body(event_type: 'document.finished', data: data) }

    it 'yields the event_type and event_data to the block' do
      yielded_event = nil
      yielded_data  = nil

      processor.process do |event, event_data|
        yielded_event = event
        yielded_data  = event_data
      end

      expect(yielded_event).to eq('document.finished')
      expect(yielded_data['id']).to eq('doc-789')
    end

    it 'returns nil when no block is given' do
      expect(processor.process).to be_nil
    end

    context 'with an unknown event type' do
      let(:body) { json_body(event_type: 'unknown.event') }

      it 'raises WebhookError' do
        expect { processor.process }
          .to raise_error(Autentique::WebhookError, /Unknown event/)
      end
    end

    context 'when signature verification fails' do
      subject(:processor) { described_class.new(body, secret: secret, signature: 'wrong_sig') }

      let(:secret) { 'whsec_test_secret' }

      before { stub_secure_compare }

      it 'raises InvalidSignatureError before yielding' do
        expect { processor.process { nil } }
          .to raise_error(Autentique::InvalidSignatureError, /signature verification failed/)
      end

      it 'never yields to the block' do
        block_called = false
        begin
          processor.process { block_called = true }
        rescue Autentique::InvalidSignatureError
          nil
        end
        expect(block_called).to be(false)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Event predicate helpers
  # ---------------------------------------------------------------------------
  describe '#document_event?' do
    it 'returns true for document.created' do
      expect(described_class.new(json_body(event_type: 'document.created')).document_event?).to be(true)
    end

    it 'returns true for document.finished' do
      expect(described_class.new(json_body(event_type: 'document.finished')).document_event?).to be(true)
    end

    it 'returns false for signature.accepted' do
      expect(described_class.new(json_body(event_type: 'signature.accepted')).document_event?).to be(false)
    end

    it 'returns false for member.created' do
      expect(described_class.new(json_body(event_type: 'member.created')).document_event?).to be(false)
    end
  end

  describe '#signature_event?' do
    it 'returns true for signature.accepted' do
      expect(described_class.new(json_body(event_type: 'signature.accepted')).signature_event?).to be(true)
    end

    it 'returns true for signature.biometric_approved' do
      expect(described_class.new(json_body(event_type: 'signature.biometric_approved')).signature_event?).to be(true)
    end

    it 'returns true for signature.delivery_failed' do
      expect(described_class.new(json_body(event_type: 'signature.delivery_failed')).signature_event?).to be(true)
    end

    it 'returns false for document.finished' do
      expect(described_class.new(json_body(event_type: 'document.finished')).signature_event?).to be(false)
    end
  end

  describe '#member_event?' do
    it 'returns true for member.created' do
      expect(described_class.new(json_body(event_type: 'member.created')).member_event?).to be(true)
    end

    it 'returns true for member.deleted' do
      expect(described_class.new(json_body(event_type: 'member.deleted')).member_event?).to be(true)
    end

    it 'returns false for document.created' do
      expect(described_class.new(json_body(event_type: 'document.created')).member_event?).to be(false)
    end
  end

  # ---------------------------------------------------------------------------
  # SUPPORTED_EVENTS constant
  # ---------------------------------------------------------------------------
  describe 'SUPPORTED_EVENTS' do
    subject(:events) { described_class::SUPPORTED_EVENTS }

    it 'includes all document lifecycle events' do
      expect(events).to include(
        'document.created', 'document.updated', 'document.deleted', 'document.finished'
      )
    end

    it 'includes all signature events' do
      expect(events).to include(
        'signature.created', 'signature.updated', 'signature.deleted',
        'signature.viewed', 'signature.accepted', 'signature.rejected',
        'signature.biometric_approved', 'signature.biometric_unapproved',
        'signature.biometric_rejected', 'signature.delivery_failed'
      )
    end

    it 'includes member events' do
      expect(events).to include('member.created', 'member.deleted')
    end

    it 'is frozen' do
      expect(events).to be_frozen
    end
  end
end
