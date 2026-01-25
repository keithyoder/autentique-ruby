#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'autentique'

# Advanced usage example for Autentique Ruby gem

client = Autentique::Client.new(
  api_key: ENV.fetch('AUTENTIQUE_API_KEY', nil),
  sandbox: true
)

# Example 1: Create a document with multiple signers and advanced options
puts 'Example 1: Advanced document creation'
puts '=' * 50

document = client.documents.create(
  file: '/path/to/contract.pdf',
  document: {
    name: 'Employment Contract - Advanced',
    message: 'Please review and sign this employment contract carefully.',
    reminder: 'WEEKLY',
    sortable: true,              # Signers must sign in order
    refusable: true,             # Allow rejection
    qualified: true,             # Qualified signature
    scrolling_required: true,    # Must scroll entire document
    stop_on_rejected: true,      # Stop if rejected
    new_signature_style: true,
    deadline_at: '2025-12-31T23:59:59.999Z',
    configs: {
      notification_finished: true,
      notification_signed: true,
      signature_appearance: 'DRAW'
    },
    locale: {
      country: 'BR',
      language: 'pt-BR',
      timezone: 'America/Sao_Paulo',
      date_format: 'DD_MM_YYYY'
    }
  },
  signers: [
    # Signer 1: Employee with CPF validation and positioned signature
    {
      email: 'employee@company.com',
      action: 'SIGN',
      configs: { cpf: '12345678900' },
      positions: [
        { x: 10.0, y: 85.0, z: 1, element: 'SIGNATURE' },
        { x: 10.0, y: 75.0, z: 1, element: 'DATE' },
        { x: 10.0, y: 65.0, z: 1, element: 'CPF' }
      ]
    },
    # Signer 2: Witness with SMS verification
    {
      phone: '+5511999999999',
      delivery_method: 'DELIVERY_METHOD_SMS',
      action: 'SIGN_AS_A_WITNESS',
      security_verifications: [
        { type: 'SMS', verify_phone: '+5511999999999' }
      ],
      positions: [
        { x: 60.0, y: 85.0, z: 1, element: 'NAME' },
        { x: 60.0, y: 75.0, z: 1, element: 'DATE' }
      ]
    },
    # Signer 3: HR Manager with photo ID verification
    {
      email: 'hr@company.com',
      action: 'APPROVE',
      security_verifications: [
        { type: 'UPLOAD' } # Photo ID upload
      ],
      positions: [
        { x: 10.0, y: 50.0, z: 2, element: 'SIGNATURE' }
      ]
    },
    # Signer 4: WhatsApp delivery with biometric verification
    {
      phone: '+5511988888888',
      delivery_method: 'DELIVERY_METHOD_WHATSAPP',
      action: 'SIGN',
      security_verifications: [
        { type: 'BIOMETRIC_AND_TEXT_EXTRACTION' }
      ]
    }
  ]
)

puts "Document created with ID: #{document.id}"
puts "Total signers: #{document.signatures.count}"
document.signatures.each_with_index do |sig, i|
  puts "  #{i + 1}. #{sig.email || sig.name} - #{sig.link['short_link']}"
end
puts "\n"

# Example 2: Using model classes for type safety
puts 'Example 2: Using model classes'
puts '=' * 50

doc_input = Autentique::Models::DocumentInput.new(
  name: 'Contract with Models',
  reminder: 'DAILY',
  refusable: false,
  configs: {
    notification_finished: true
  }
)

signer1 = Autentique::Models::SignerInput.new(
  email: 'signer1@example.com',
  action: 'SIGN'
)

signer2 = Autentique::Models::SignerInput.new(
  email: 'signer2@example.com',
  action: 'SIGN'
)

doc_with_models = client.documents.create(
  file: '/path/to/contract.pdf',
  document: doc_input,
  signers: [signer1, signer2]
)

puts "Document created: #{doc_with_models.name}"
puts "\n"

# Example 3: Error handling
puts 'Example 3: Error handling'
puts '=' * 50

begin
  # Try to retrieve a non-existent document
  client.documents.find('invalid-uuid')
rescue Autentique::NotFoundError => e
  puts "Caught NotFoundError: #{e.message}"
rescue Autentique::Error => e
  puts "Caught general error: #{e.message}"
end

begin
  # Try to create document with invalid data
  client.documents.create(
    file: '/nonexistent/file.pdf',
    document: { name: 'Test' },
    signers: []
  )
rescue Autentique::ValidationError => e
  puts "Caught ValidationError: #{e.message}"
rescue Autentique::UploadError => e
  puts "Caught UploadError: #{e.message}"
rescue Autentique::Error => e
  puts "Caught general error: #{e.message}"
end
puts "\n"

# Example 4: Monitoring document status
puts 'Example 4: Monitoring document status'
puts '=' * 50

def check_document_status(client, document_id) # rubocop:disable Metrics/AbcSize
  doc = client.documents.find(document_id)

  puts "Document: #{doc.name}"
  puts "Overall status: #{doc.signed? ? '✓ Signed' : '⏳ Pending'}"

  puts '⚠️  Document was rejected' if doc.rejected?

  puts "\nSignature details:"
  doc.signatures.each do |sig|
    email_or_name = sig.email || sig.name || sig.phone

    if sig.signed?
      puts "  ✓ #{email_or_name} - Signed on #{sig.signed['created_at']}"
    elsif sig.rejected?
      puts "  ✗ #{email_or_name} - Rejected: #{sig.rejected['reason']}"
    else
      puts "  ⏳ #{email_or_name} - Waiting for signature"
      puts "     Link: #{sig.short_link}"
    end
  end
end

check_document_status(client, document.id)
puts "\n"

# Example 5: Batch operations
puts 'Example 5: Batch operations'
puts '=' * 50

contracts = [
  { file: 'contract1.pdf', name: 'Contract 1', email: 'signer1@example.com' },
  { file: 'contract2.pdf', name: 'Contract 2', email: 'signer2@example.com' },
  { file: 'contract3.pdf', name: 'Contract 3', email: 'signer3@example.com' }
]

created_docs = []

contracts.each do |contract|
  doc = client.documents.create(
    file: contract[:file],
    document: { name: contract[:name] },
    signers: [{ email: contract[:email], action: 'SIGN' }]
  )
  created_docs << doc
  puts "✓ Created: #{doc.name}"
rescue Autentique::Error => e
  puts "✗ Failed to create #{contract[:name]}: #{e.message}"
end

puts "\nSuccessfully created #{created_docs.count} documents"
puts "\n"

# Example 6: Working with international documents
puts 'Example 6: International document'
puts '=' * 50

intl_doc = client.documents.create(
  file: '/path/to/contract.pdf',
  document: {
    name: 'International Contract',
    locale: {
      country: 'US',
      language: 'en-US',
      timezone: 'America/New_York',
      date_format: 'MM_DD_YYYY'
    },
    ignore_cpf: true,
    new_signature_style: true
  },
  signers: [
    {
      email: 'client@international.com',
      action: 'SIGN'
    }
  ]
)

puts "International document created: #{intl_doc.id}"
puts 'Country: US, Language: en-US'

puts "\n#{'=' * 50}"
puts 'All advanced examples completed!'
