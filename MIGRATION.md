# Migration Guide

This guide helps you migrate from direct Autentique GraphQL API usage to the Autentique Ruby gem.

## Overview

The Autentique Ruby gem provides a more Ruby-idiomatic interface to the Autentique API, with:
- Better error handling
- Type-safe models
- Cleaner syntax
- Built-in multipart upload handling
- Comprehensive documentation

## Before and After

### Old Code (Direct GraphQL)

```ruby
module Autentique
  HTTP = GraphQL::Client::HTTP.new('https://api.autentique.com.br/v2/graphql') do
    def headers(_context)
      { Authorization: "Bearer #{Rails.application.credentials.autentique_key}" }
    end
  end

  def self.client
    @client ||= begin
      schema = GraphQL::Client.load_schema(HTTP)
      GraphQL::Client.new(schema: schema, execute: HTTP)
    end
  end

  def self.resgatar_documento
    @resgatar_documento ||= client.parse <<-GRAPHQL
      query($id: UUID!) {
        document(id: $id) {
          id
          name
          # ... more fields
        }
      }
    GRAPHQL
  end
end

# Usage
result = Autentique::Client.query(
  Autentique::resgatar_documento,
  variables: { "id": document_id }
)
document = result.original_hash['data']['document']
```

### New Code (Using Gem)

```ruby
# Initialization (once)
Autentique.configure do |config|
  config.api_key = Rails.application.credentials.autentique_key
end

# Usage
client = Autentique.client
document = client.documents.find(document_id)
```

## Common Migration Scenarios

### 1. Retrieving a Document

**Before:**
```ruby
documento = Autentique::Client.query(
  Autentique::resgatar_documento,
  variables: { "id": id }
).original_hash['data']['document']

documentos_array = documentos.presence || []
update(
  documentos: documentos_array + [
    {
      'data' => documento['created_at'],
      'nome' => documento['name'],
      'link' => documento['files']['signed']
    }
  ]
)
```

**After:**
```ruby
client = Autentique.client
documento = client.documents.find(id)

documentos_array = documentos.presence || []
update(
  documentos: documentos_array + [
    {
      'data' => documento.created_at,
      'nome' => documento.name,
      'link' => documento.files['signed']
    }
  ]
)
```

### 2. Creating a Document

**Before:**
```ruby
# Complex multipart upload with manual boundary handling
mutation = <<-GRAPHQL
  mutation CreateDocumentMutation($document: DocumentInput!, $signers: [SignerInput!]!, $file: Upload!) {
    createDocument(document: $document, signers: $signers, file: $file) {
      id
      name
    }
  }
GRAPHQL

# Manual file upload handling with boundaries
# ... 50+ lines of code ...
```

**After:**
```ruby
client = Autentique.client
documento = client.documents.create(
  file: '/path/to/contract.pdf',
  document: {
    name: 'Contract',
    reminder: 'WEEKLY'
  },
  signers: [
    {
      email: 'signer@example.com',
      action: 'SIGN'
    }
  ]
)
```

### 3. Listing Pending Documents

**Before:**
```ruby
query = client.parse <<-GRAPHQL
  query {
    documents(status: PENDING, limit: 60, page: 1) {
      total
      data {
        id
        name
        created_at
      }
    }
  }
GRAPHQL

result = Autentique::Client.query(query)
documents = result.data.documents.data
```

**After:**
```ruby
client = Autentique.client
documents = client.documents.pending(limit: 60, page: 1)
```

## Model Integration

### Old Approach

```ruby
class Contrato < ApplicationRecord
  def vincular_documento(id)
    require 'autentique'

    documento = Autentique::Client.query(
      Autentique::resgatar_documento,
      variables: { "id": id }
    ).original_hash['data']['document']
    
    documentos_array = documentos.presence || []
    update(
      documentos: documentos_array + [
        {
          'data' => documento['created_at'],
          'nome' => documento['name'],
          'link' => documento['files']['signed']
        }
      ]
    )
  end
end
```

### New Approach

```ruby
class Contrato < ApplicationRecord
  def vincular_documento(id)
    client = Autentique.client
    documento = client.documents.find(id)
    
    documentos_array = documentos.presence || []
    update(
      documentos: documentos_array + [
        {
          'data' => documento.created_at,
          'nome' => documento.name,
          'link' => documento.files['signed']
        }
      ]
    )
  end
  
  # Better: use a dedicated method for creating documents
  def criar_documento_assinatura
    client = Autentique.client
    
    documento = client.documents.create(
      file: gerar_pdf,
      document: {
        name: "Contrato #{id} - #{pessoa.nome}",
        message: 'Por favor, assine este contrato',
        reminder: 'WEEKLY'
      },
      signers: [
        {
          email: pessoa.email,
          action: 'SIGN',
          configs: { cpf: pessoa.cpf }
        }
      ]
    )
    
    vincular_documento(documento.id)
    documento
  end
end
```

## Configuration

### Rails Initializer

**Before:**
```ruby
# Scattered configuration in module
module Autentique
  HTTP = GraphQL::Client::HTTP.new('https://api.autentique.com.br/v2/graphql') do
    def headers(_context)
      { Authorization: "Bearer #{Rails.application.credentials.autentique_key}" }
    end
  end
end
```

**After:**
```ruby
# config/initializers/autentique.rb
Autentique.configure do |config|
  config.api_key = Rails.application.credentials.autentique_key
  config.sandbox = Rails.env.development? || Rails.env.test?
end
```

## Error Handling

### Before
```ruby
begin
  result = Autentique::Client.query(query, variables: vars)
  if result.errors.any?
    # Handle errors
  end
rescue StandardError => e
  # Generic error handling
end
```

### After
```ruby
begin
  document = client.documents.find(id)
rescue Autentique::NotFoundError => e
  # Handle not found
rescue Autentique::AuthenticationError => e
  # Handle auth error
rescue Autentique::RateLimitError => e
  # Handle rate limit
rescue Autentique::Error => e
  # Handle any Autentique error
end
```

## Benefits of Migration

1. **Less Code**: Reduce boilerplate by 70%+
2. **Better Errors**: Specific error classes for different scenarios
3. **Type Safety**: Model classes instead of raw hashes
4. **Maintainability**: Easier to update when API changes
5. **Documentation**: Comprehensive docs and examples
6. **Testing**: Built-in VCR support for testing
7. **Community**: Shared improvements and bug fixes

## Step-by-Step Migration

1. **Install the gem**
   ```ruby
   gem 'autentique'
   ```

2. **Create initializer**
   ```ruby
   # config/initializers/autentique.rb
   Autentique.configure do |config|
     config.api_key = Rails.application.credentials.autentique_key
     config.sandbox = !Rails.env.production?
   end
   ```

3. **Update your models**
   - Replace direct GraphQL queries with gem methods
   - Use model classes for type safety
   - Add proper error handling

4. **Update tests**
   - Use VCR cassettes
   - Test with sandbox mode
   - Mock external API calls

5. **Deploy gradually**
   - Test in development
   - Deploy to staging
   - Monitor in production
   - Roll back if needed

## Troubleshooting

### Issue: API key not working

**Solution**: Check that your API key is correctly set in credentials:
```ruby
Rails.application.credentials.autentique_key
```

### Issue: Rate limit errors

**Solution**: The gem respects rate limits. Use batch operations wisely:
```ruby
contratos.find_each do |contrato|
  contrato.enviar_para_assinatura
  sleep 1 # Add delay between requests
end
```

### Issue: File upload fails

**Solution**: Ensure file exists and is readable:
```ruby
file_path = Rails.root.join('tmp', 'contract.pdf')
raise "File not found" unless File.exist?(file_path)

client.documents.create(file: file_path, ...)
```

## Need Help?

- Check the [README](README.md) for detailed documentation
- See [examples](examples/) for code samples
- Open an [issue](https://github.com/yourusername/autentique-ruby/issues) for bugs
- Start a [discussion](https://github.com/yourusername/autentique-ruby/discussions) for questions

## Rollback Plan

If you need to rollback:

1. Keep your old code alongside the gem temporarily
2. Use feature flags to switch between implementations
3. Monitor error rates and performance
4. Roll back if issues persist

```ruby
class Contrato < ApplicationRecord
  def criar_documento_assinatura
    if Rails.configuration.use_autentique_gem
      criar_com_gem
    else
      criar_com_graphql_direto
    end
  end
end
```
