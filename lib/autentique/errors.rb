# frozen_string_literal: true

module Autentique
  # Base error class for all Autentique errors
  class Error < StandardError; end

  # Raised when API authentication fails
  class AuthenticationError < Error; end

  # Raised when API rate limit is exceeded
  class RateLimitError < Error; end

  # Raised when a resource is not found
  class NotFoundError < Error; end

  # Raised when validation fails
  class ValidationError < Error; end

  # Raised when file upload fails
  class UploadError < Error; end

  # Raised when GraphQL query fails
  class QueryError < Error
    attr_reader :errors

    def initialize(message, errors = [])
      super(message)
      @errors = errors
    end
  end
end
