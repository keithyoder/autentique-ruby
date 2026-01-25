#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'autentique'

# Basic usage example for Autentique Ruby gem

# Initialize the client
client = Autentique::Client.new(
  api_key: ENV['AUTENTIQUE_API_KEY'] || 'your_api_key_here',
  sandbox: true # Set to false for production
)

# Example 1: Create a simple document
puts 'Example 1: Creating a simple document'
puts '=' * 50

document = client.documents.create(
  file: '/path/to/contract.pdf', # Change this to your file path
  document: {
    name: 'Simple Contract'
  },
  signers: [
    {
      email: 'signer@example.com',
      action: 'SIGN'
    }
  ]
)

puts 'Document created successfully!'
puts "Document ID: #{document.id}"
puts "Document name: #{document.name}"
puts "Signature link: #{document.signatures.first.short_link}"
puts "\n"

# Example 2: Retrieve a document
puts 'Example 2: Retrieving a document'
puts '=' * 50

retrieved_doc = client.documents.find(document.id)
puts "Document: #{retrieved_doc.name}"
puts "Status: #{retrieved_doc.signed? ? 'Signed' : 'Pending'}"
puts "Number of signatures: #{retrieved_doc.signatures.count}"
puts "\n"

# Example 3: List pending documents
puts 'Example 3: Listing pending documents'
puts '=' * 50

pending_docs = client.documents.pending(limit: 10)
puts "Found #{pending_docs.count} pending documents"
pending_docs.each_with_index do |doc, index|
  puts "#{index + 1}. #{doc.name} (ID: #{doc.id})"
end
puts "\n"

# Example 4: Check document status
puts 'Example 4: Checking signatures status'
puts '=' * 50

retrieved_doc.signatures.each do |signature|
  status = if signature.signed?
             'Signed'
           elsif signature.rejected?
             'Rejected'
           else
             'Pending'
           end

  puts "Signer: #{signature.email || signature.name}"
  puts "Status: #{status}"
  puts "Link: #{signature.short_link}" if signature.pending?
  puts '---'
end
puts "\n"

# Example 5: Working with folders
puts 'Example 5: Working with folders'
puts '=' * 50

folder = client.folders.create(name: 'Example Contracts')
puts "Created folder: #{folder['name']} (ID: #{folder['id']})"

folders = client.folders.list
puts "Total folders: #{folders.count}"
puts "\n"

puts 'All examples completed successfully!'
