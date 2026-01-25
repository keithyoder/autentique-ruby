# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Autentique::Configuration do
  describe 'initialization' do
    subject(:config) { described_class.new }

    it 'initializes api_key from environment variable' do
      ENV['AUTENTIQUE_API_KEY'] = 'env_test_key'
      new_config = described_class.new
      expect(new_config.api_key).to eq('env_test_key')
      ENV.delete('AUTENTIQUE_API_KEY')
    end

    it 'defaults sandbox to false' do
      expect(config.sandbox).to be false
    end

    context 'when AUTENTIQUE_API_KEY is not set' do
      before { ENV.delete('AUTENTIQUE_API_KEY') }

      it 'api_key is nil' do
        expect(described_class.new.api_key).to be_nil
      end
    end
  end

  describe 'attribute accessors' do
    subject(:config) { described_class.new }

    it 'allows setting api_key' do
      config.api_key = 'new_key'
      expect(config.api_key).to eq('new_key')
    end

    it 'allows setting sandbox' do
      config.sandbox = true
      expect(config.sandbox).to be true
    end
  end
end
