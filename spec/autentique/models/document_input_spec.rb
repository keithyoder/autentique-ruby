# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Autentique::Models::DocumentInput do
  describe '#initialize' do
    subject(:doc_input) { described_class.new(attributes) }

    let(:attributes) do
      {
        name: 'Test Document',
        message: 'Please sign this',
        reminder: 'WEEKLY',
        sortable: true,
        refusable: false,
        qualified: true,
        scrolling_required: true,
        stop_on_rejected: true,
        new_signature_style: true,
        configs: { notification_finished: true }
      }
    end

    it 'sets name attribute' do
      expect(doc_input.name).to eq('Test Document')
    end

    it 'sets message attribute' do
      expect(doc_input.message).to eq('Please sign this')
    end

    it 'sets reminder attribute' do
      expect(doc_input.reminder).to eq('WEEKLY')
    end

    it 'sets sortable attribute' do
      expect(doc_input.sortable).to be true
    end

    it 'sets refusable attribute' do
      expect(doc_input.refusable).to be false
    end

    it 'sets qualified attribute' do
      expect(doc_input.qualified).to be true
    end

    it 'sets scrolling_required attribute' do
      expect(doc_input.scrolling_required).to be true
    end

    it 'sets stop_on_rejected attribute' do
      expect(doc_input.stop_on_rejected).to be true
    end

    it 'sets new_signature_style attribute' do
      expect(doc_input.new_signature_style).to be true
    end

    it 'sets configs attribute' do
      expect(doc_input.configs).to eq({ notification_finished: true })
    end

    context 'with unknown attributes' do
      let(:attributes) { { name: 'Test', unknown_field: 'value' } }

      it 'ignores unknown attributes' do
        expect { doc_input }.not_to raise_error
        expect(doc_input).not_to respond_to(:unknown_field)
      end
    end
  end

  describe '#to_h' do
    context 'with all attributes set' do
      let(:attributes) do
        {
          name: 'Test Document',
          message: 'Sign this',
          reminder: 'DAILY',
          sortable: true,
          footer: 'BOTTOM',
          refusable: true,
          qualified: true,
          scrolling_required: true,
          stop_on_rejected: true,
          new_signature_style: true,
          show_audit_page: true,
          ignore_cpf: false,
          ignore_birthdate: false,
          email_template_id: 'template-123',
          deadline_at: '2025-12-31T23:59:59.999Z',
          cc: ['manager@example.com'],
          expiration: '30',
          configs: { notification_finished: true },
          locale: { country: 'BR', language: 'pt-BR' }
        }
      end

      it 'returns a hash with all attributes' do
        doc_input = described_class.new(attributes)
        hash = doc_input.to_h

        expect(hash).to eq(attributes)
      end
    end

    context 'with some attributes set' do
      let(:attributes) do
        {
          name: 'Test Document',
          reminder: 'WEEKLY',
          refusable: true
        }
      end

      it 'returns a hash with only set attributes' do
        doc_input = described_class.new(attributes)
        hash = doc_input.to_h

        expect(hash).to eq(attributes)
        expect(hash.keys).to contain_exactly(:name, :reminder, :refusable)
      end
    end

    context 'with nil attributes' do
      let(:attributes) { { name: 'Test', message: nil } }

      it 'excludes nil values from hash' do
        doc_input = described_class.new(attributes)
        hash = doc_input.to_h

        expect(hash).to eq({ name: 'Test' })
        expect(hash).not_to have_key(:message)
      end
    end
  end

  describe 'attribute setters' do
    subject(:doc_input) { described_class.new }

    it 'allows setting name' do
      doc_input.name = 'New Name'
      expect(doc_input.name).to eq('New Name')
    end

    it 'allows setting message' do
      doc_input.message = 'New message'
      expect(doc_input.message).to eq('New message')
    end

    it 'allows setting reminder' do
      doc_input.reminder = 'MONTHLY'
      expect(doc_input.reminder).to eq('MONTHLY')
    end

    it 'allows setting configs' do
      configs = { notification_signed: true }
      doc_input.configs = configs
      expect(doc_input.configs).to eq(configs)
    end
  end
end
