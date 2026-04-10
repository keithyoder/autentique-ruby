# frozen_string_literal: true

require_relative 'autentique/version'
require_relative 'autentique/errors'
require_relative 'autentique/client'
require_relative 'autentique/models/document'
require_relative 'autentique/resources'
require_relative 'autentique/resources/documents'
require_relative 'autentique/resources/folders'
require_relative 'autentique/webhook_processor'

# Main module for the Autentique gem
#
# @example Basic usage
#   client = Autentique::Client.new(api_key: 'your_api_key')
#
#   # Create a document
#   document = client.documents.create(
#     file: '/path/to/contract.pdf',
#     document: { name: 'Contract' },
#     signers: [
#       { email: 'signer@example.com', action: 'SIGN' }
#     ]
#   )
#
#   # Retrieve a document
#   doc = client.documents.find('document-uuid')
#
#   # List pending documents
#   pending_docs = client.documents.pending
#
module Autentique
  class << self
    # Configure the Autentique client with default settings
    #
    # @yield [Configuration] configuration object
    # @return [Configuration]
    def configure
      yield configuration
    end

    # Get the current configuration
    #
    # @return [Configuration]
    def configuration
      @configuration ||= Configuration.new
    end

    # Create a new client with default configuration
    #
    # @return [Client]
    def client
      @client ||= Client.new(
        api_key: configuration.api_key,
        sandbox: configuration.sandbox
      )
    end

    # Reset the configuration
    def reset
      @configuration = Configuration.new
      @client = nil
    end
  end

  # Configuration class for global settings
  class Configuration
    attr_accessor :api_key, :sandbox

    def initialize
      @api_key = ENV.fetch('AUTENTIQUE_API_KEY', nil)
      @sandbox = false
    end
  end
end
