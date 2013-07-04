require 'multi_mail/mailgun/message'

module MultiMail
  module Sender
    # Mailgun's outgoing mail sender.
    class Mailgun
      include MultiMail::Sender::Base

      requires :api_key, :domain

      attr_reader :api_key, :domain

      # Initializes a Mailgun outgoing email sender.
      #
      # @param [Hash] options required and optional arguments
      # @option options [String] :api_key a Mailgun API key
      def initialize(options = {})
        super
        @api_key = settings.delete(:api_key)
        @domain  = settings.delete(:domain)
      end

      # Delivers a message via the Mailgun API.
      #
      # @param [Mail::Message] mail a message
      def deliver!(mail)
        parameters = settings.dup
        parameters.delete(:return_response)
        message = MultiMail::Message::Mailgun.new(mail).to_mailgun_hash.merge(parameters)

        connection = Faraday.new do |conn|
          conn.request :multipart
          conn.request :url_encoded
          conn.adapter Faraday.default_adapter
        end

        response = connection.post("https://api:#{api_key}@api.mailgun.net/v2/#{domain}/messages", message)

        case response.status
        when 401
          raise InvalidAPIKey
        when 400
          raise InvalidMessage
        when 200
          body = JSON.load(response.body)
        else
          raise response.body.inspect
        end

        if settings[:return_response]
          body
        else
          self
        end
      end
    end
  end
end
