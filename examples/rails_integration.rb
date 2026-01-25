#!/usr/bin/env ruby
# frozen_string_literal: true

# ============================================
# Rails Integration Example for Autentique
# ============================================
#
# This example shows how to initialize the Autentique gem in a Rails app
# and use its main features: creating, finding, listing, and deleting documents.
# It also demonstrates working with signatures.
#
# Copy this file to your Rails project and adapt paths/emails as needed.

# ============================================
# 1. INITIALIZER
# config/initializers/autentique.rb
# ============================================

Autentique.configure do |config|
  config.api_key = Rails.application.credentials.dig(:autentique, :api_key) || ENV.fetch('AUTENTIQUE_API_KEY', nil)
  config.sandbox = Rails.env.development? || Rails.env.test?
end

# ============================================
# 2. GETTING THE CLIENT
# ============================================

# Get a client instance to interact with the API
client = Autentique.client

# ============================================
# 3. CREATING A DOCUMENT
# ============================================

file_path = Rails.root.join('tmp', 'example.pdf') # Your PDF file path

# Document configuration
document_config = {
  name: 'Example Document',
  message: 'Please sign this document'
}

# Signers configuration
signers_config = [
  { email: 'user@example.com', action: 'SIGN' },
  { email: 'manager@example.com', action: 'SIGN' }
]

# Create the document
doc = client.documents.create(
  file: file_path,
  document: document_config,
  signers: signers_config
)

puts "Document created with ID: #{doc.id}"

# ============================================
# 4. FINDING A DOCUMENT
# ============================================

doc_id = doc.id

fetched_doc = client.documents.find(doc_id)

puts "Document name: #{fetched_doc.name}"
puts "Signed? #{fetched_doc.signed?}"
puts "Pending? #{fetched_doc.pending?}"
puts "Rejected? #{fetched_doc.rejected?}"

# ============================================
# 5. LISTING DOCUMENTS
# ============================================

# List pending documents
pending_docs = client.documents.pending(limit: 50, page: 1)

puts "\nPending documents:"
pending_docs.each do |d|
  puts "#{d.id} - #{d.name} (#{d.signatures.size} signatures)"
end

# List all documents with optional status filter
all_docs = client.documents.list(status: 'SIGNED', limit: 50)

puts "\nSigned documents:"
all_docs.each do |d|
  puts "#{d.id} - #{d.name} (Status: #{d.signed? ? 'signed' : 'pending'})"
end

# ============================================
# 6. DELETING A DOCUMENT
# ============================================

deleted = client.documents.delete(doc.id)

puts deleted ? "\nDocument deleted successfully" : "\nFailed to delete document"

# ============================================
# 7. WORKING WITH SIGNATURES
# ============================================

puts "\nSignatures for document #{doc.id}:"
fetched_doc.signatures.each do |sig|
  puts "#{sig.name} (#{sig.email}):"
  puts "  Signed? #{sig.signed?}"
  puts "  Rejected? #{sig.rejected?}"
  puts "  Pending? #{sig.pending?}"
  puts "  Link: #{sig.short_link}"
end

# ============================================
# End of Rails Integration Example
# ============================================

puts "\nAutentique Rails integration example complete!"
