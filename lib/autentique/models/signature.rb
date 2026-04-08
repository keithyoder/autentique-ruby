# frozen_string_literal: true

module Autentique
  module Models
    class Signature
      attr_reader :public_id, :name, :email, :created_at, :action, :link,
                  :user, :viewed, :signed, :rejected, :email_events, :delivery_method

      def initialize(attributes = {})
        @public_id = attributes['public_id']
        @name = attributes['name']
        @email = attributes['email']
        @created_at = attributes['created_at']
        @action = attributes['action']
        @link = attributes['link']
        @user = attributes['user']
        @viewed = attributes['viewed']
        @signed = attributes['signed']
        @rejected = attributes['rejected']
        @email_events = attributes['email_events']
        @delivery_method = attributes['delivery_method']
      end

      def signed?
        !@signed.nil?
      end

      def rejected?
        !@rejected.nil?
      end

      def pending?
        @signed.nil? && @rejected.nil?
      end

      def short_link
        @link&.dig('short_link')
      end
    end
  end
end
