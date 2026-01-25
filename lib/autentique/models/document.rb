# frozen_string_literal: true

require_relative 'document_input'
require_relative 'signer_input'
require_relative 'signature'

module Autentique
  module Models
    class Document
      attr_reader :id, :name, :refusable, :sortable, :created_at, :signatures, :files

      def initialize(attributes = {})
        @id = attributes['id']
        @name = attributes['name']
        @refusable = attributes['refusable']
        @sortable = attributes['sortable']
        @created_at = attributes['created_at']
        @signatures = parse_signatures(attributes['signatures'])
        @files = attributes['files']
      end

      def signed?
        signatures.all?(&:signed?)
      end

      def pending?
        !signed?
      end

      def rejected?
        signatures.any?(&:rejected?)
      end

      private

      def parse_signatures(signatures_data)
        return [] unless signatures_data

        signatures_data.map { |sig| Signature.new(sig) }
      end
    end
  end
end
