# Documents

## Creating Documents

The `file` argument accepts a file path (String), a `File` object, or a `StringIO` object. When passing a `StringIO`, also provide `filename` so the API receives the correct name and MIME type.

### Basic creation

```ruby
document = client.documents.create(
  file: '/path/to/contract.pdf',
  document: { name: 'Employment Contract' },
  signers: [{ email: 'employee@example.com', action: 'SIGN' }]
)

puts document.id
puts document.signatures.first.short_link
```

### From a File object or StringIO

```ruby
# File object
document = client.documents.create(
  file: File.open('/path/to/contract.pdf'),
  document: { name: 'Contract' },
  signers: [{ email: 'signer@example.com', action: 'SIGN' }]
)

# StringIO (e.g. a PDF generated in memory)
pdf_io = StringIO.new(pdf_bytes)
document = client.documents.create(
  file: pdf_io,
  filename: 'contract.pdf',
  document: { name: 'Contract' },
  signers: [{ email: 'signer@example.com', action: 'SIGN' }]
)
```

### Advanced creation

```ruby
document = client.documents.create(
  file: '/path/to/contract.pdf',
  document: {
    name: 'Marketing Contract',
    message: 'Please review and sign this contract',
    reminder: 'WEEKLY',
    sortable: true,
    refusable: true,
    qualified: true,
    scrolling_required: true,
    stop_on_rejected: true,
    new_signature_style: true,
    deadline_at: '2025-12-31T23:59:59.999Z',
    configs: {
      notification_finished: true,
      notification_signed: true,
      signature_appearance: 'DRAW'
    }
  },
  signers: [
    {
      email: 'signer1@example.com',
      action: 'SIGN',
      configs: { cpf: '12345678900' },
      positions: [{ x: 5.0, y: 90.0, z: 1, element: 'SIGNATURE' }]
    },
    {
      name: 'Witness Name',
      action: 'SIGN_AS_A_WITNESS',
      positions: [{ x: 75.0, y: 90.0, z: 1, element: 'NAME' }]
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
  folder_id: 'folder-uuid'
)
```

## Signer Actions

| Action | Description |
|--------|-------------|
| `SIGN` | Sign the document |
| `SIGN_AS_A_WITNESS` | Sign as a witness |
| `APPROVE` | Approve the document |
| `RECOGNIZE` | Acknowledge the document |

## Delivery Methods

Used when identifying a signer by phone rather than email:

| Method | Description |
|--------|-------------|
| `DELIVERY_METHOD_WHATSAPP` | Send invitation via WhatsApp |
| `DELIVERY_METHOD_SMS` | Send invitation via SMS |

## Security Verifications

```ruby
signers: [
  {
    email: 'signer@example.com',
    action: 'SIGN',
    security_verifications: [
      { type: 'SMS', verify_phone: '+5554999999999' },
      { type: 'MANUAL' },
      { type: 'UPLOAD' },
      { type: 'LIVE' },
      { type: 'PF_FACIAL' },
      { type: 'BIOMETRIC_AND_TEXT_EXTRACTION' }
    ]
  }
]
```

| Type | Description |
|------|-------------|
| `SMS` | SMS code sent to `verify_phone` |
| `MANUAL` | Manual photo ID approval by document creator |
| `UPLOAD` | Signer uploads a photo ID |
| `LIVE` | Selfie with liveness check |
| `PF_FACIAL` | SERPRO biometric validation |
| `BIOMETRIC_AND_TEXT_EXTRACTION` | Photo ID with facematch |

## Using Model Classes

For better type safety and IDE support:

```ruby
doc_input = Autentique::Models::DocumentInput.new(
  name: 'Contract',
  reminder: 'WEEKLY',
  refusable: true
)

signer = Autentique::Models::SignerInput.new(
  email: 'signer@example.com',
  action: 'SIGN',
  positions: [{ x: 10.0, y: 90.0, z: 1, element: 'SIGNATURE' }]
)

document = client.documents.create(
  file: 'contract.pdf',
  document: doc_input,
  signers: [signer]
)
```

## Retrieving a Document

```ruby
document = client.documents.find('document-uuid')

puts document.name
puts document.signed? ? 'Signed' : 'Pending'

document.signatures.each do |sig|
  puts sig.email
  puts sig.signed? ? 'Signed' : 'Pending'
  puts sig.short_link if sig.pending?
end
```

## Listing Documents

```ruby
# Pending documents
pending = client.documents.pending(limit: 20, page: 1)

# All documents, with optional status filter
all      = client.documents.list
signed   = client.documents.list(status: 'SIGNED', limit: 50)
rejected = client.documents.list(status: 'REJECTED')
```

## Deleting a Document

```ruby
client.documents.delete('document-uuid')
```

## Rejecting a Document

Programmatically reject a document on behalf of a signer. Useful for orphaned or superseded documents.

```ruby
client.documents.reject('document-uuid', reason: 'Contract terms need revision')
```

The `reason` parameter is optional.

## Sandbox Mode

Test without consuming document credits:

```ruby
# At the client level
client = Autentique::Client.new(api_key: 'your_api_key', sandbox: true)

# Per request
document = client.documents.create(
  file: '/path/to/test.pdf',
  document: { name: 'Test Doc' },
  signers: [{ email: 'test@example.com', action: 'SIGN' }],
  sandbox: true
)
```