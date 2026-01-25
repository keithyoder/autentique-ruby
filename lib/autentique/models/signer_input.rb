# frozen_string_literal: true

module Autentique
  module Models
    class SignerInput
      attr_accessor :email, :phone, :name, :action, :delivery_method,
                    :configs, :security_verifications, :positions

      def initialize(attributes = {})
        attributes.each do |key, value|
          send("#{key}=", value) if respond_to?("#{key}=")
        end
      end

      def to_h
        {
          email: email,
          phone: phone,
          name: name,
          action: action,
          delivery_method: delivery_method,
          configs: configs,
          security_verifications: security_verifications,
          positions: positions
        }.compact
      end
    end
  end
end
