# frozen_string_literal: true

require 'spec_helper'

# Specs for all Autentique error classes
RSpec.describe Autentique::Error do
  # ---------------------------------------------------
  # Base Error Class
  # ---------------------------------------------------
  describe 'Autentique::Error base class' do
    it 'inherits from StandardError' do
      expect(described_class).to be < StandardError
    end

    it 'can be instantiated with a message' do
      error = described_class.new('Test error message')
      expect(error.message).to eq('Test error message')
    end

    it 'can be raised' do
      expect { raise described_class, 'Test error' }.to raise_error(described_class, 'Test error')
    end
  end

  # ---------------------------------------------------
  # Subclasses
  # ---------------------------------------------------
  [
    Autentique::AuthenticationError,
    Autentique::RateLimitError,
    Autentique::NotFoundError,
    Autentique::ValidationError,
    Autentique::UploadError
  ].each do |error_class|
    describe error_class do
      it 'inherits from Autentique::Error' do
        expect(described_class).to be < Autentique::Error # rubocop:disable RSpec/DescribedClass
      end

      it 'can be instantiated with a message' do
        msg = "Test message for #{described_class}"
        error = described_class.new(msg)
        expect(error.message).to eq(msg)
      end

      it 'can be rescued as Autentique::Error' do
        expect do
          raise described_class, 'Raised error'
        rescue described_class => e
          expect(e).to be_a(described_class)
          raise
        end.to raise_error(described_class)
      end
    end
  end

  # ---------------------------------------------------
  # QueryError (with additional errors array)
  # ---------------------------------------------------
  describe Autentique::QueryError do
    it 'inherits from Autentique::Error' do
      expect(described_class).to be < Autentique::Error
    end

    describe '#initialize' do
      it 'accepts message and errors array' do
        errors = ['Error 1', 'Error 2']
        error = described_class.new('Query failed', errors)
        expect(error.message).to eq('Query failed')
        expect(error.errors).to eq(errors)
      end

      it 'defaults errors to empty array when not provided' do
        error = described_class.new('Query failed')
        expect(error.errors).to eq([])
      end
    end

    it 'can be rescued as Autentique::Error' do
      expect do
        raise described_class.new('Query failed', ['Error'])
      rescue Autentique::Error => e
        expect(e).to be_a(described_class)
        expect(e.errors).to eq(['Error'])
        raise
      end.to raise_error(described_class)
    end
  end

  # ---------------------------------------------------
  # Error hierarchy tests
  # ---------------------------------------------------
  describe 'error hierarchy' do
    it 'allows catching all Autentique errors via Autentique::Error' do
      classes = [
        Autentique::AuthenticationError,
        Autentique::RateLimitError,
        Autentique::NotFoundError,
        Autentique::ValidationError,
        Autentique::UploadError,
        Autentique::QueryError
      ]

      classes.each do |klass|
        caught = false
        begin
          raise klass, 'Test'
        rescue described_class
          caught = true
        end
        expect(caught).to be true
      end
    end

    it 'allows catching specific error types' do
      raise Autentique::NotFoundError, 'Not found'
    rescue Autentique::NotFoundError => e
      expect(e.message).to eq('Not found')
    end

    it 'allows catching all errors via StandardError' do
      classes = [
        described_class,
        Autentique::AuthenticationError,
        Autentique::RateLimitError,
        Autentique::NotFoundError,
        Autentique::ValidationError,
        Autentique::UploadError,
        Autentique::QueryError
      ]

      classes.each do |klass|
        caught = false
        begin
          raise klass, 'Test'
        rescue StandardError
          caught = true
        end
        expect(caught).to be true
      end
    end
  end

  # ---------------------------------------------------
  # Practical handling scenarios
  # ---------------------------------------------------
  describe 'practical error handling' do
    it 'supports rescue order from specific to general' do
      result = nil
      begin
        raise Autentique::NotFoundError, 'Document not found'
      rescue Autentique::NotFoundError
        result = :not_found
      rescue described_class
        result = :general_error
      end
      expect(result).to eq(:not_found)
    end

    it 'allows re-raising errors' do
      expect { raise Autentique::ValidationError, 'Invalid input' }
        .to raise_error(Autentique::ValidationError, 'Invalid input')
    end

    it 'supports inspecting QueryError details' do
      error = Autentique::QueryError.new('Failed', ['Missing field', 'Invalid type'])
      expect(error.message).to eq('Failed')
      expect(error.errors).to include('Missing field', 'Invalid type')
    end
  end
end
