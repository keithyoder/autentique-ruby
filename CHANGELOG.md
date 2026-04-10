# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1] - 2026-04-10

### Added
- `WebhookProcessor` for parsing and verifying incoming Autentique webhook events,
  including HMAC-SHA256 signature verification via the `X-Autentique-Signature` header
- `documents.reject` for programmatically rejecting documents with an optional reason
- `InvalidSignatureError` and `WebhookError` error classes
- Comprehensive documentation split into `docs/` — documents, folders, webhooks,
  and configuration reference

### Changed
- Webhook event types updated to Autentique's current dot-notation format
  (`document.finished`, `signature.accepted`, etc.)
- Document creation now accepts file input as a path, `File`, or `StringIO` —
  `file_name` and `mime_type` kwargs removed from the public interface
- README restructured to focus on quick start, with detailed reference moved to `docs/`
- Improved test isolation for HTTP layer using `build_http_client` stub

### Fixed
- Duplicate file part bug in multipart body construction
- `GraphQLDocumentsData` struct arity mismatch in test helpers

## [0.1.0] - 2025-01-25

Initial release. A lightweight, framework-agnostic Ruby client for the
Autentique digital signature API, providing a clean idiomatic interface
over Autentique's GraphQL API.

### Added
- `Autentique::Client` with global configuration and sandbox mode support
- `client.documents` resource — create, find, list, pending, and delete
- `client.folders` resource — list, create, and delete
- Document creation supports multiple signers with email, SMS, WhatsApp,
  and link-based delivery; all signer actions (SIGN, SIGN_AS_A_WITNESS,
  APPROVE, RECOGNIZE); security verifications (SMS, photo ID, biometric,
  SERPRO); signature field positioning; and advanced document configurations
- `Autentique::Models::Document`, `Signature`, `DocumentInput`, and
  `SignerInput` model classes for type safety
- Structured error handling with `AuthenticationError`, `RateLimitError`,
  `ValidationError`, `QueryError`, and `UploadError`
- Runtime dependencies: `graphql-client ~> 0.18`, `mime-types ~> 3.0`

## [Unreleased]: https://github.com/keithyoder/autentique-ruby/compare/v0.1.1...HEAD
## [0.1.1]: https://github.com/keithyoder/autentique-ruby/compare/v0.1.0...v0.1.1
## [0.1.0]: https://github.com/keithyoder/autentique-ruby/releases/tag/v0.1.0