# frozen_string_literal: true

module Autentique
  module Resources
    class Documents
      module Create
        def create(file:, document:, signers:, organization_id: nil, folder_id: nil, sandbox: nil) # rubocop:disable Metrics/ParameterLists
          doc_input = document.is_a?(Models::DocumentInput) ? document : Models::DocumentInput.new(document)
          signer_inputs = signers.map { |s| s.is_a?(Models::SignerInput) ? s : Models::SignerInput.new(s) }

          use_sandbox = sandbox.nil? ? client.sandbox : sandbox
          if use_sandbox
            doc_hash = doc_input.to_h.merge(sandbox: true)
            doc_input = Models::DocumentInput.new(doc_hash)
          end

          response = upload_document(file: file, document: doc_input, signers: signer_inputs,
                                     organization_id: organization_id, folder_id: folder_id)

          document_data = response.dig('data', 'createDocument')
          raise QueryError.new('Failed to create document', response['errors']) if document_data.nil?

          Models::Document.new(document_data)
        end
      end
    end
  end
end
