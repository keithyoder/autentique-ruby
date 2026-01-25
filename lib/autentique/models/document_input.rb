# frozen_string_literal: true

module Autentique
  module Models
    class DocumentInput
      attr_accessor :name, :message, :reminder, :sortable, :footer, :refusable,
                    :qualified, :scrolling_required, :stop_on_rejected,
                    :new_signature_style, :show_audit_page, :ignore_cpf,
                    :ignore_birthdate, :email_template_id, :deadline_at,
                    :cc, :expiration, :configs, :locale

      def initialize(attributes = {})
        attributes.each do |key, value|
          send("#{key}=", value) if respond_to?("#{key}=")
        end
      end

      def to_h
        {
          name: name,
          message: message,
          reminder: reminder,
          sortable: sortable,
          footer: footer,
          refusable: refusable,
          qualified: qualified,
          scrolling_required: scrolling_required,
          stop_on_rejected: stop_on_rejected,
          new_signature_style: new_signature_style,
          show_audit_page: show_audit_page,
          ignore_cpf: ignore_cpf,
          ignore_birthdate: ignore_birthdate,
          email_template_id: email_template_id,
          deadline_at: deadline_at,
          cc: cc,
          expiration: expiration,
          configs: configs,
          locale: locale
        }.compact
      end
    end
  end
end
