# frozen_string_literal: true

RSpec.describe Autentique::Models::SignerInput do
  describe '#initialize' do
    subject(:signer_input) { described_class.new(attributes) }

    let(:attributes) do
      {
        email: 'signer@example.com',
        phone: '+5511999999999',
        name: 'John Doe',
        action: 'SIGN',
        delivery_method: 'DELIVERY_METHOD_EMAIL',
        configs: { cpf: '12345678900' },
        security_verifications: [{ type: 'SMS' }],
        positions: [{ x: 10.0, y: 90.0, z: 1, element: 'SIGNATURE' }]
      }
    end

    it 'sets email attribute' do
      expect(signer_input.email).to eq('signer@example.com')
    end

    it 'sets phone attribute' do
      expect(signer_input.phone).to eq('+5511999999999')
    end

    it 'sets name attribute' do
      expect(signer_input.name).to eq('John Doe')
    end

    it 'sets action attribute' do
      expect(signer_input.action).to eq('SIGN')
    end

    it 'sets delivery_method attribute' do
      expect(signer_input.delivery_method).to eq('DELIVERY_METHOD_EMAIL')
    end

    it 'sets configs attribute' do
      expect(signer_input.configs).to eq({ cpf: '12345678900' })
    end

    it 'sets security_verifications attribute' do
      expect(signer_input.security_verifications).to eq([{ type: 'SMS' }])
    end

    it 'sets positions attribute' do
      expect(signer_input.positions).to eq([{ x: 10.0, y: 90.0, z: 1, element: 'SIGNATURE' }])
    end

    context 'with unknown attributes' do
      let(:attributes) { { email: 'test@example.com', unknown_field: 'value' } }

      it 'ignores unknown attributes' do
        expect { signer_input }.not_to raise_error
        expect(signer_input).not_to respond_to(:unknown_field)
      end
    end
  end

  describe '#to_h' do
    context 'with all attributes set' do
      let(:attributes) do
        {
          email: 'signer@example.com',
          phone: '+5511999999999',
          name: 'John Doe',
          action: 'SIGN',
          delivery_method: 'DELIVERY_METHOD_WHATSAPP',
          configs: { cpf: '12345678900' },
          security_verifications: [{ type: 'SMS', verify_phone: '+5511999999999' }],
          positions: [{ x: 10.0, y: 90.0, z: 1, element: 'SIGNATURE' }]
        }
      end

      it 'returns a hash with all attributes' do
        signer_input = described_class.new(attributes)
        hash = signer_input.to_h

        expect(hash).to eq(attributes)
      end
    end

    context 'with minimal attributes' do
      let(:attributes) do
        {
          email: 'signer@example.com',
          action: 'SIGN'
        }
      end

      it 'returns a hash with only set attributes' do
        signer_input = described_class.new(attributes)
        hash = signer_input.to_h

        expect(hash).to eq(attributes)
        expect(hash.keys).to contain_exactly(:email, :action)
      end
    end

    context 'with nil attributes' do
      let(:attributes) { { email: 'test@example.com', name: nil, action: 'SIGN' } }

      it 'excludes nil values from hash' do
        signer_input = described_class.new(attributes)
        hash = signer_input.to_h

        expect(hash).to eq({ email: 'test@example.com', action: 'SIGN' })
        expect(hash).not_to have_key(:name)
      end
    end
  end

  describe 'attribute setters' do
    subject(:signer_input) { described_class.new }

    it 'allows setting email' do
      signer_input.email = 'new@example.com'
      expect(signer_input.email).to eq('new@example.com')
    end

    it 'allows setting action' do
      signer_input.action = 'APPROVE'
      expect(signer_input.action).to eq('APPROVE')
    end

    it 'allows setting positions' do
      positions = [{ x: 50.0, y: 50.0, z: 1, element: 'NAME' }]
      signer_input.positions = positions
      expect(signer_input.positions).to eq(positions)
    end

    it 'allows setting security_verifications' do
      verifications = [{ type: 'UPLOAD' }]
      signer_input.security_verifications = verifications
      expect(signer_input.security_verifications).to eq(verifications)
    end
  end
end
