# frozen_string_literal: true

require 'openssl'
require 'json'

module Autentique
  class WebhookProcessor
    SUPPORTED_EVENTS = %w[
      document.created document.updated document.deleted document.finished
      signature.created signature.updated signature.deleted signature.viewed
      signature.accepted signature.rejected signature.biometric_approved
      signature.biometric_unapproved signature.biometric_rejected signature.delivery_failed
      member.created member.deleted
    ].freeze

    attr_reader :payload, :event_type

    def initialize(body, secret: nil, signature: nil)
      @secret = secret
      @signature = signature
      @payload = parse_payload(body)
      @event_type = @payload['event']['type']
    end

    # Verify HMAC-SHA256 signature from the X-Autentique-Signature header
    def valid_signature?
      return true if @secret.nil?

      expected = OpenSSL::HMAC.hexdigest('SHA256', @secret, @payload.to_json)
      if defined?(ActiveSupport::SecurityUtils)
        ActiveSupport::SecurityUtils.secure_compare(expected, @signature.to_s)
      else
        expected == @signature.to_s
      end
    rescue StandardError
      false
    end

    # Process the webhook, yielding event_type and event data to the block
    def process
      raise InvalidSignatureError, 'Webhook signature verification failed' unless valid_signature?
      raise WebhookError, "Unknown event: #{event_type}" unless SUPPORTED_EVENTS.include?(event_type)

      yield(event_type, event_data) if block_given?
    end

    # The event object from the payload
    def event
      @payload['event']
    end

    # The data object from the event (the document, signature, or member)
    def event_data
      @payload['event']['data']
    end

    # The previous attributes for *.updated events
    def previous_attributes
      @payload['event']['previous_attributes']
    end

    # Convenience predicates
    def document_event?
      event_type.to_s.start_with?('document.')
    end

    def signature_event?
      event_type.to_s.start_with?('signature.')
    end

    def member_event?
      event_type.to_s.start_with?('member.')
    end

    private

    def parse_payload(body)
      JSON.parse(body)
    rescue JSON::ParserError
      raise ArgumentError, 'Invalid webhook payload: could not parse as JSON'
    end
  end
end
