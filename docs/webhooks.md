# Webhooks

Autentique sends webhook events to your registered HTTPS endpoint as JSON payloads whenever actions occur in your organisation. The `Autentique::WebhookProcessor` class handles parsing, signature verification, and dispatching.

Webhook endpoints are configured through the [Autentique Developer Panel](https://painel.autentique.com.br). The API does not support managing endpoints programmatically.

## Basic Processing

```ruby
processor = Autentique::WebhookProcessor.new(request.body.read)

processor.process do |event_type, data|
  case event_type
  when 'document.finished'
    puts "Document #{data['id']} is fully signed"
  when 'signature.accepted'
    puts "#{data['user']['name']} signed document #{data['document']}"
  when 'member.created'
    puts "New member: #{data['user']['name']}"
  end
end
```

The block receives `event_type` (a string such as `"document.finished"`) and `data` (the resource object — a document, signature, or member hash).

## Verifying Signatures

Autentique signs each request with an HMAC-SHA256 signature sent in the `X-Autentique-Signature` header. Pass your webhook secret and that header value to enable verification:

```ruby
processor = Autentique::WebhookProcessor.new(
  request.body.read,
  secret: ENV['AUTENTIQUE_WEBHOOK_SECRET'],
  signature: request.headers['X-Autentique-Signature']
)

processor.process do |event_type, data|
  # Only reached if the signature is valid
end
```

If the signature is invalid, `process` raises `Autentique::InvalidSignatureError`. If the event type is unrecognised, it raises `Autentique::WebhookError`. When no `secret` is provided, signature checking is skipped.

## Accessing Payload Data Directly

```ruby
processor = Autentique::WebhookProcessor.new(request.body.read)

processor.event_type          # => "document.updated"
processor.event               # => full event object (id, type, organization, created_at, ...)
processor.event_data          # => the resource object (document, signature, or member)
processor.previous_attributes # => changed fields, present on *.updated events
```

## Event Predicates

```ruby
processor.document_event?  # => true for document.*
processor.signature_event? # => true for signature.*
processor.member_event?    # => true for member.*
```

## Rails Controller Example

Return a 2xx response immediately and process the event asynchronously. Autentique will retry failed deliveries up to three times (after 60, 120, and 300 seconds).

```ruby
class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    processor = Autentique::WebhookProcessor.new(
      request.body.read,
      secret: Rails.application.credentials.dig(:autentique, :webhook_secret),
      signature: request.headers['X-Autentique-Signature']
    )

    ProcessAutentiqueWebhookJob.perform_later(
      event_type: processor.event_type,
      data: processor.event_data,
      previous_attributes: processor.previous_attributes
    )

    head :ok
  rescue Autentique::InvalidSignatureError
    head :unauthorized
  rescue Autentique::WebhookError, ArgumentError
    head :bad_request
  end
end
```

## Handling Duplicate Events

Autentique does not guarantee exactly-once delivery. Protect against duplicates by storing processed event IDs:

```ruby
processor.process do |event_type, data|
  event_id = processor.event['id']
  next if ProcessedWebhookEvent.exists?(event_id: event_id)

  ProcessedWebhookEvent.create!(event_id: event_id)
  # process the event...
end
```

## Supported Event Types

### Document Events

| Event | Description |
|-------|-------------|
| `document.created` | New document created |
| `document.updated` | Document settings changed — `previous_attributes` shows what changed |
| `document.deleted` | Document permanently deleted |
| `document.finished` | All signatures completed |

### Signature Events

| Event | Description |
|-------|-------------|
| `signature.created` | New signature request created for a signer |
| `signature.updated` | Signature request updated |
| `signature.deleted` | Pending signer removed from the document |
| `signature.viewed` | Signer viewed the document for the first time |
| `signature.accepted` | Signer completed the signature |
| `signature.rejected` | Signer declined the signature |
| `signature.biometric_approved` | Biometric verification approved |
| `signature.biometric_unapproved` | Biometric verification pending manual review |
| `signature.biometric_rejected` | Biometric verification rejected |
| `signature.delivery_failed` | Email delivery to signer failed |

### Member Events

| Event | Description |
|-------|-------------|
| `member.created` | New member joined the organisation |
| `member.deleted` | Member removed from the organisation |

## Event Ordering

Autentique does not guarantee delivery order. For example, `document.updated` may arrive before `document.created`. Design your handler to be order-independent, and use the API to retrieve any missing data if needed.