# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Autentique do
  describe 'module-level usage' do
    before do
      described_class.configure { |c| c.api_key = 'module_test_key' }
    end

    after { described_class.reset }

    it 'allows using client without explicit initialization' do
      client = described_class.client
      expect(client).to be_a(Autentique::Client)
      expect(client.api_key).to eq('module_test_key')
    end

    it 'provides access to documents through module client' do
      documents = described_class.client.documents
      expect(documents).to be_a(Autentique::Resources::Documents)
    end

    it 'provides access to folders through module client' do
      folders = described_class.client.folders
      expect(folders).to be_a(Autentique::Resources::Folders)
    end

    it 'memoizes the client' do
      client1 = described_class.client
      client2 = described_class.client
      expect(client1).to be(client2)
    end
  end
end
