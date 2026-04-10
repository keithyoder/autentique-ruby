# Autentique Ruby Gem

A Ruby client for the [Autentique](https://autentique.com.br/) digital signature API. This gem provides a clean, idiomatic interface to Autentique's GraphQL API for document signing and management.

[![CI](https://github.com/keithyoder/autentique-ruby/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/keithyoder/autentique-ruby/actions/workflows/ci.yml)
[![Security](https://github.com/keithyoder/autentique-ruby/actions/workflows/security.yml/badge.svg?branch=main)](https://github.com/keithyoder/autentique-ruby/actions/workflows/security.yml)
[![Gem Version](https://badge.fury.io/rb/autentique.svg)](https://badge.fury.io/rb/autentique)
[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%202.7.0-ruby.svg)](https://www.ruby-lang.org)

## Features

- 🔐 **Simple Authentication** — Easy API key configuration
- 📄 **Document Management** — Create, retrieve, list, and delete documents
- ✍️ **Flexible Signing** — Multiple signers with various authentication methods
- 📁 **Folder Management** — Organize documents in folders
- 🪝 **Webhook Processing** — Verify and process incoming Autentique webhook events
- 🏖️ **Sandbox Mode** — Test without consuming document credits
- 🛡️ **Type Safety** — Model classes for structured data

## Installation

Add to your Gemfile:

```ruby
gem 'autentique'
```

Then run `bundle install`, or install directly with `gem install autentique`.

## Quick Start

```ruby
client = Autentique::Client.new(api_key: ENV['AUTENTIQUE_API_KEY'])

# Create a document
document = client.documents.create(
  file: '/path/to/contract.pdf',
  document: { name: 'Employment Contract' },
  signers: [{ email: 'employee@example.com', action: 'SIGN' }]
)

puts document.id
puts document.signatures.first.short_link

# Retrieve a document
doc = client.documents.find('document-uuid')
puts doc.signed? ? 'Signed' : 'Pending'

# Process an incoming webhook
processor = Autentique::WebhookProcessor.new(
  request.body.read,
  secret: ENV['AUTENTIQUE_WEBHOOK_SECRET'],
  signature: request.headers['X-Autentique-Signature']
)

processor.process do |event_type, data|
  puts "#{event_type}: #{data['id']}"
end
```

## Configuration

### Environment variable

```ruby
client = Autentique::Client.new(api_key: ENV['AUTENTIQUE_API_KEY'])
```

### Global configuration (recommended for Rails)

```ruby
Autentique.configure do |config|
  config.api_key = Rails.application.credentials.dig(:autentique, :api_key)
  config.sandbox = Rails.env.development? || Rails.env.test?
end

client = Autentique.client
```

### Rails initializer

Create `config/initializers/autentique.rb`:

```ruby
Autentique.configure do |config|
  config.api_key = Rails.application.credentials.dig(:autentique, :api_key)
  config.sandbox = Rails.env.development? || Rails.env.test?
end
```

## Error Handling

```ruby
begin
  document = client.documents.create(...)
rescue Autentique::AuthenticationError => e
  # Invalid or missing API key
rescue Autentique::RateLimitError => e
  # 60 requests/minute limit exceeded
rescue Autentique::ValidationError => e
  # Invalid input
rescue Autentique::QueryError => e
  # GraphQL query failed — e.errors contains details
rescue Autentique::UploadError => e
  # File upload failed
rescue Autentique::InvalidSignatureError => e
  # Webhook signature verification failed
rescue Autentique::WebhookError => e
  # Unknown webhook event type or processing error
rescue Autentique::Error => e
  # Base class for all gem errors
end
```

## Documentation

- [Documents](docs/documents.md) — creating, retrieving, listing, deleting, and rejecting documents
- [Folders](docs/folders.md) — folder management
- [Webhooks](docs/webhooks.md) — processing incoming webhook events
- [Configuration Reference](docs/configuration.md) — all document and signer options

## Testing

```bash
bundle exec rspec
COVERAGE=true bundle exec rspec
```

## Development

```bash
git clone https://github.com/keithyoder/autentique-ruby.git
cd autentique-ruby
bundle install
bundle exec rspec
gem build autentique.gemspec
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes (`git commit -am 'Add my feature'`)
4. Push to the branch (`git push origin feature/my-feature`)
5. Open a Pull Request

## Resources

- [Autentique API Documentation](https://docs.autentique.com.br/api)
- [Autentique Dashboard](https://painel.autentique.com.br)
- [GraphQL Explorer](https://altair.autentique.com.br)
- [API Keys](https://painel.autentique.com.br/perfil/api)

## License

Available as open source under the [MIT License](LICENSE).

## Acknowledgments

This gem is not officially maintained by Autentique. It is a community-driven project to simplify Ruby integration with the Autentique API.

## Support

- 🐛 [Report bugs](https://github.com/keithyoder/autentique-ruby/issues)
- 💬 [Ask questions](https://github.com/keithyoder/autentique-ruby/discussions)

## Changelog

See [CHANGELOG.md](CHANGELOG.md).