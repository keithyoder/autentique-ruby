# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2025-01-25

### Added
- Initial release of the Autentique Ruby gem
- Client class for API communication
- Document resource with create, find, list, and delete operations
- Folder resource for folder management
- Model classes for Document, Signature, DocumentInput, and SignerInput
- Full support for document creation with:
  - Multiple signers
  - Various authentication methods (email, SMS, WhatsApp)
  - Security verifications (SMS, photo ID, biometric)
  - Signature field positioning
  - Advanced document configurations
- Sandbox mode support for testing
- Comprehensive error handling
- Rate limit awareness (60 requests/minute)
- Rails integration examples
- Complete documentation and examples

### Features
- ✅ Create documents with file upload
- ✅ Retrieve documents by ID
- ✅ List documents with filters
- ✅ Delete documents
- ✅ Folder management (list, create, delete)
- ✅ Support for all signer actions (SIGN, SIGN_AS_A_WITNESS, APPROVE, RECOGNIZE)
- ✅ Multiple delivery methods (email, SMS, WhatsApp, link-based)
- ✅ Security verifications
- ✅ Signature field positioning
- ✅ Document locale support
- ✅ Sandbox mode
- ✅ Comprehensive error handling

### Dependencies
- graphql-client ~> 0.18
- mime-types ~> 3.0

### Development Dependencies
- rspec ~> 3.12
- webmock ~> 3.18
- vcr ~> 6.1
- rubocop ~> 1.50

## [0.0.1] - 2025-01-24

### Added
- Project structure
- Basic gem scaffolding

[Unreleased]: https://github.com/yourusername/autentique-ruby/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/yourusername/autentique-ruby/releases/tag/v0.1.0
[0.0.1]: https://github.com/yourusername/autentique-ruby/releases/tag/v0.0.1
