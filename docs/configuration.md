# Configuration Reference

## Document Options

Passed as the `document:` hash to `client.documents.create`.

| Option | Type | Description |
|--------|------|-------------|
| `name` | String | Document name (required) |
| `message` | String | Custom message shown to signers |
| `reminder` | String | Reminder frequency: `WEEKLY` or `DAILY` |
| `sortable` | Boolean | Signers must sign in order |
| `refusable` | Boolean | Allow signers to reject the document |
| `qualified` | Boolean | Enable qualified signatures |
| `scrolling_required` | Boolean | Require full scroll before signing |
| `stop_on_rejected` | Boolean | Stop the signing process if any signer rejects |
| `new_signature_style` | Boolean | Use new signature field style |
| `show_audit_page` | Boolean | Show an audit page at the end |
| `ignore_cpf` | Boolean | Do not require CPF validation |
| `ignore_birthdate` | Boolean | Do not require birthdate validation |
| `footer` | String | Footer position: `BOTTOM`, `LEFT`, or `RIGHT` |
| `deadline_at` | DateTime | Signing deadline (ISO 8601) |
| `configs` | Hash | Additional document configurations (see below) |

### Document Config Options

Passed as `document: { configs: { ... } }`.

| Option | Type | Description |
|--------|------|-------------|
| `notification_finished` | Boolean | Notify author when all signers have signed |
| `notification_signed` | Boolean | Notify each signer after they sign |
| `signature_appearance` | String | Force signature style: `DRAW`, `TYPED`, or `UPLOAD` |

## Signer Options

Each entry in the `signers:` array accepts the following:

| Option | Type | Description |
|--------|------|-------------|
| `email` | String | Signer's email address |
| `phone` | String | Signer's phone number (for SMS/WhatsApp delivery) |
| `name` | String | Signer's name (used for link-based signing) |
| `action` | String | Action type (required) — see actions below |
| `delivery_method` | String | How to contact the signer — see delivery methods below |
| `configs` | Hash | Additional signer configs (see below) |
| `security_verifications` | Array | Extra identity verification steps |
| `positions` | Array | Signature field positions on the document |

### Signer Actions

| Value | Description |
|-------|-------------|
| `SIGN` | Sign the document |
| `SIGN_AS_A_WITNESS` | Sign as a witness |
| `APPROVE` | Approve without signing |
| `RECOGNIZE` | Acknowledge the document |

### Delivery Methods

| Value | Description |
|-------|-------------|
| `DELIVERY_METHOD_WHATSAPP` | Send invitation via WhatsApp |
| `DELIVERY_METHOD_SMS` | Send invitation via SMS |

### Signer Config Options

Passed as `signers: [{ configs: { ... } }]`.

| Option | Type | Description |
|--------|------|-------------|
| `cpf` | String | Require signer to match this CPF |

### Signature Position Options

Each entry in `positions:` accepts:

| Option | Type | Description |
|--------|------|-------------|
| `x` | Float | Horizontal position (percentage from left) |
| `y` | Float | Vertical position (percentage from top) |
| `z` | Integer | Page number (1-based) |
| `element` | String | Field type: `SIGNATURE`, `INITIALS`, `NAME`, `DATE`, `CPF` |

### Security Verification Types

| Type | Description |
|------|-------------|
| `SMS` | SMS code sent to `verify_phone` |
| `MANUAL` | Manual photo ID approval by document creator |
| `UPLOAD` | Signer uploads a photo ID |
| `LIVE` | Selfie with liveness detection |
| `PF_FACIAL` | SERPRO biometric validation |
| `BIOMETRIC_AND_TEXT_EXTRACTION` | Photo ID with facematch |

## Client Options

Passed to `Autentique::Client.new`.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `api_key` | String | — | Your Autentique API key (required) |
| `sandbox` | Boolean | `false` | Enable sandbox mode |

## Global Configuration

```ruby
Autentique.configure do |config|
  config.api_key = 'your_api_key'
  config.sandbox = false
end
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `api_key` | String | `ENV['AUTENTIQUE_API_KEY']` | Your Autentique API key |
| `sandbox` | Boolean | `false` | Enable sandbox mode globally |