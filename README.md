# Autentique Ruby Gem

A Ruby client for the [Autentique](https://autentique.com.br/) digital signature API. This gem provides a clean, idiomatic Ruby interface to Autentique's GraphQL API for document signing and management.

[![CI](https://github.com/keithyoder/autentique-ruby/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/keithyoder/autentique-ruby/actions/workflows/ci.yml)
[![Security](https://github.com/keithyoder/autentique-ruby/actions/workflows/security.yml/badge.svg?branch=main)](https://github.com/keithyoder/autentique-ruby/actions/workflows/security.yml)
[![Gem Version](https://badge.fury.io/rb/nfcom.svg)](https://badge.fury.io/rb/nfcom)

## Features

- 🔐 **Simple Authentication** - Easy API key configuration
- 📄 **Document Management** - Create, retrieve, list, and delete documents
- ✍️ **Flexible Signing** - Support for multiple signers with various authentication methods
- 🏖️ **Sandbox Mode** - Test without consuming document credits
- 🔍 **Advanced Queries** - Full GraphQL query support
- 📁 **Folder Management** - Organize documents in folders
- 🛡️ **Type Safety** - Model classes for structured data
- ⚡ **Rate Limiting** - Built-in rate limit handling (60 requests/minute)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'autentique'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install autentique
```

## Configuration

### Using Environment Variables

```ruby
# Set your API key as an environment variable
ENV['AUTENTIQUE_API_KEY'] = 'your_api_key_here'

# Create a client
client = Autentique::Client.new(api_key: ENV['AUTENTIQUE_API_KEY'])
```

### Global Configuration

```ruby
Autentique.configure do |config|
  config.api_key = 'your_api_key_here'
  config.sandbox = false # Set to true for testing
end

# Use the configured client
client = Autentique.client
```

### Direct Initialization

```ruby
client = Autentique::Client.new(
  api_key: 'your_api_key_here',
  sandbox: false
)
```

## Usage

### Creating Documents

#### Basic Document Creation

```ruby
client = Autentique::Client.new(api_key: 'your_api_key')

document = client.documents.create(
  file: '/path/to/contract.pdf',
  document: {
    name: 'Employment Contract'
  },
  signers: [
    {
      email: 'employee@example.com',
      action: 'SIGN'
    }
  ]
)

puts "Document created: #{document.id}"
puts "Signature link: #{document.signatures.first.short_link}"
```

#### Advanced Document Creation

```ruby
document = client.documents.create(
  file: File.open('/path/to/contract.pdf'),
  document: {
    name: 'Marketing Contract',
    message: 'Please review and sign this contract',
    reminder: 'WEEKLY',        # Send weekly reminders
    sortable: true,            # Signers must sign in order
    refusable: true,           # Allow document rejection
    qualified: true,           # Enable qualified signatures
    scrolling_required: true,  # Require full scroll before signing
    stop_on_rejected: true,    # Stop process if rejected
    new_signature_style: true, # Use new signature fields
    deadline_at: '2025-12-31T23:59:59.999Z',
    configs: {
      notification_finished: true, # Notify when all signed
      notification_signed: true,   # Notify signer after signing
      signature_appearance: 'DRAW' # Force signature style
    }
  },
  signers: [
    {
      email: 'signer1@example.com',
      action: 'SIGN',
      configs: { cpf: '12345678900' }, # Validate CPF
      positions: [
        { x: 5.0, y: 90.0, z: 1, element: 'SIGNATURE' }
      ]
    },
    {
      name: 'Witness Name',
      action: 'SIGN_AS_A_WITNESS',
      positions: [
        { x: 75.0, y: 90.0, z: 1, element: 'NAME' }
      ]
    },
    {
      phone: '+5554999999999',
      delivery_method: 'DELIVERY_METHOD_WHATSAPP',
      action: 'SIGN',
      security_verifications: [
        { type: 'SMS', verify_phone: '+5554999999999' }
      ]
    }
  ],
  folder_id: 'folder-uuid' # Optional: organize in folder
)
```

#### Document Actions

Signers can perform different actions:
- `SIGN` - Sign the document
- `SIGN_AS_A_WITNESS` - Sign as a witness
- `APPROVE` - Approve the document
- `RECOGNIZE` - Acknowledge the document

#### Delivery Methods

For phone-based signers:
- `DELIVERY_METHOD_WHATSAPP` - Send via WhatsApp
- `DELIVERY_METHOD_SMS` - Send via SMS

#### Security Verifications

Add extra security layers:

```ruby
signers: [
  {
    email: 'signer@example.com',
    action: 'SIGN',
    security_verifications: [
      { type: 'SMS', verify_phone: '+5554999999999' }, # SMS verification
      { type: 'MANUAL' },                               # Manual photo ID approval
      { type: 'UPLOAD' },                               # Photo ID upload
      { type: 'LIVE' },                                 # Selfie + liveness check
      { type: 'PF_FACIAL' },                           # SERPRO biometric
      { type: 'BIOMETRIC_AND_TEXT_EXTRACTION' }        # Photo ID + facematch
    ]
  }
]
```

### Retrieving Documents

```ruby
# Get a specific document
document = client.documents.find('document-uuid')

puts "Document: #{document.name}"
puts "Status: #{document.signed? ? 'Signed' : 'Pending'}"

document.signatures.each do |signature|
  puts "Signer: #{signature.email}"
  puts "Status: #{signature.signed? ? 'Signed' : 'Pending'}"
  puts "Link: #{signature.short_link}" if signature.pending?
end
```

### Listing Documents

```ruby
# List pending documents
pending = client.documents.pending(limit: 20, page: 1)

pending.each do |doc|
  puts "#{doc.name} - #{doc.id}"
end

# List all documents with filter
signed_docs = client.documents.list(status: 'SIGNED', limit: 50)
rejected_docs = client.documents.list(status: 'REJECTED')
all_docs = client.documents.list(limit: 100)
```

### Deleting Documents

```ruby
client.documents.delete('document-uuid')
```

### Working with Folders

```ruby
# List folders
folders = client.folders.list
folders.each { |f| puts "#{f['name']} - #{f['id']}" }

# Create a folder
folder = client.folders.create(name: 'Contracts 2025')
puts "Created folder: #{folder['id']}"

# Delete a folder
client.folders.delete(id: 'folder-uuid')
```

### Sandbox Mode

Test without consuming document credits:

```ruby
# Enable sandbox globally
client = Autentique::Client.new(
  api_key: 'your_api_key',
  sandbox: true
)

# Or per request
document = client.documents.create(
  file: '/path/to/test.pdf',
  document: { name: 'Test Doc' },
  signers: [{ email: 'test@example.com', action: 'SIGN' }],
  sandbox: true
)
```

### Using Model Classes

For better type safety and IDE support:

```ruby
# Use DocumentInput model
doc_input = Autentique::Models::DocumentInput.new(
  name: 'Contract',
  reminder: 'WEEKLY',
  refusable: true
)

# Use SignerInput model
signer = Autentique::Models::SignerInput.new(
  email: 'signer@example.com',
  action: 'SIGN',
  positions: [
    { x: 10.0, y: 90.0, z: 1, element: 'SIGNATURE' }
  ]
)

document = client.documents.create(
  file: 'contract.pdf',
  document: doc_input,
  signers: [signer]
)
```

### Rails Integration

#### Initializer

Create `config/initializers/autentique.rb`:

```ruby
Autentique.configure do |config|
  config.api_key = Rails.application.credentials.dig(:autentique, :api_key)
  config.sandbox = Rails.env.development? || Rails.env.test?
end
```

#### In Your Models

```ruby
class Contrato < ApplicationRecord
  belongs_to :pessoa
  
  def enviar_para_assinatura
    client = Autentique.client
    
    documento = client.documents.create(
      file: gerar_pdf,
      document: {
        name: "Contrato #{id}",
        message: 'Por favor, assine este contrato'
      },
      signers: [
        {
          email: pessoa.email,
          action: 'SIGN',
          configs: { cpf: pessoa.cpf }
        }
      ]
    )
    
    update(
      documentos: (documentos || []) << {
        'id' => documento.id,
        'nome' => documento.name,
        'data' => documento.created_at
      }
    )
    
    documento
  end
  
  def verificar_assinatura(documento_id)
    client = Autentique.client
    documento = client.documents.find(documento_id)
    
    if documento.signed?
      update(status: :assinado)
    elsif documento.rejected?
      update(status: :rejeitado)
    end
    
    documento
  end
end
```

### Error Handling

```ruby
begin
  document = client.documents.create(
    file: 'contract.pdf',
    document: { name: 'Contract' },
    signers: [{ email: 'invalid@email', action: 'SIGN' }]
  )
rescue Autentique::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
rescue Autentique::RateLimitError => e
  puts "Rate limit exceeded: #{e.message}"
rescue Autentique::ValidationError => e
  puts "Validation error: #{e.message}"
rescue Autentique::QueryError => e
  puts "Query failed: #{e.message}"
  puts "Errors: #{e.errors.inspect}"
rescue Autentique::UploadError => e
  puts "Upload failed: #{e.message}"
rescue Autentique::Error => e
  puts "General error: #{e.message}"
end
```

## API Coverage

### Implemented

- ✅ Create documents with file upload
- ✅ Retrieve document by ID
- ✅ List pending documents
- ✅ List all documents with filters
- ✅ Delete documents
- ✅ List folders
- ✅ Create folders
- ✅ Delete folders
- ✅ Sandbox mode support
- ✅ All signer options
- ✅ Security verifications
- ✅ Signature positioning
- ✅ Document configurations

### Roadmap

- ⏳ Webhooks support
- ⏳ Document templates
- ⏳ Bulk operations
- ⏳ Organization management
- ⏳ User management

## Configuration Options

### Document Options

| Option | Type | Description |
|--------|------|-------------|
| `name` | String | Document name (required) |
| `message` | String | Custom message for signers |
| `reminder` | String | Reminder frequency (`WEEKLY`, `DAILY`) |
| `sortable` | Boolean | Signers must sign in order |
| `footer` | String | Footer position (`BOTTOM`, `LEFT`, `RIGHT`) |
| `refusable` | Boolean | Allow document rejection |
| `qualified` | Boolean | Enable qualified signatures |
| `scrolling_required` | Boolean | Require full scroll before signing |
| `stop_on_rejected` | Boolean | Stop when document is rejected |
| `new_signature_style` | Boolean | Use new signature fields |
| `show_audit_page` | Boolean | Show audit page |
| `ignore_cpf` | Boolean | Don't require CPF |
| `ignore_birthdate` | Boolean | Don't require birthdate |
| `deadline_at` | DateTime | Signing deadline |

### Signer Options

| Option | Type | Description |
|--------|------|-------------|
| `email` | String | Signer's email |
| `phone` | String | Signer's phone (for SMS/WhatsApp) |
| `name` | String | Signer's name (for link-based signing) |
| `action` | String | Action type (required) |
| `delivery_method` | String | Delivery method for phone signers |
| `configs` | Hash | Additional configs (e.g., CPF) |
| `security_verifications` | Array | Security checks |
| `positions` | Array | Signature field positions |

## Rate Limiting

The Autentique API has a rate limit of **60 requests per minute**. The gem automatically handles rate limit errors.

## Testing

```bash
# Install dependencies
bundle install

# Run tests
bundle exec rspec

# Run with coverage
COVERAGE=true bundle exec rspec
```

## Development

```bash
# Clone the repository
git clone https://github.com/yourusername/autentique-ruby.git
cd autentique-ruby

# Install dependencies
bundle install

# Run tests
bundle exec rspec

# Run console
bin/console

# Build gem
gem build autentique.gemspec

# Install locally
gem install autentique-0.1.0.gem
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -am 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Resources

- [Autentique Official Documentation](https://docs.autentique.com.br/api)
- [Autentique Dashboard](https://painel.autentique.com.br)
- [GraphQL Altair Explorer](https://altair.autentique.com.br)
- [API Keys](https://painel.autentique.com.br/perfil/api)

## License

This gem is available as open source under the terms of the [MIT License](LICENSE).

## Acknowledgments

This gem is not officially maintained by Autentique. It's a community-driven project to make integration easier for Ruby developers.

## Support

- 🐛 Report bugs: [GitHub Issues](https://github.com/yourusername/autentique-ruby/issues)
- 💬 Questions: [GitHub Discussions](https://github.com/yourusername/autentique-ruby/discussions)

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a list of changes.
