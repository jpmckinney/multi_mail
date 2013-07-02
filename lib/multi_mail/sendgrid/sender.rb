require 'multi_mail/sendgrid/message'

module MultiMail
  module Sender
    # SendGrid's outgoing mail sender.
    class SendGrid
      include MultiMail::Sender::Base

      # Initializes a SendGrid outgoing email sender.
      #
      # @param [Hash] options required and optional arguments
      # @option options [String] :api_user a SendGrid API user
      # @option options [String] :api_key a SendGrid API key
      # @see http://sendgrid.com/docs/API_Reference/Web_API/
      def initialize(options = {})
        raise ArgumentError, "Missing required arguments: :api_user" unless options[:api_user]
        raise ArgumentError, "Missing required arguments: :api_key" unless options[:api_key]
        @settings = options.dup
        settings['x-smtpapi'] ||= settings.delete(:'x-smtpapi')
        if settings['x-smtpapi'] && settings['x-smtpapi'] === Hash
          settings['x-smtpapi'] = JSON.dump(params['x-smtpapi'])
        end
      end

      # Delivers a message via the SendGrid API.
      #
      # @param [Mail::Message] mail a message
      # @see http://sendgrid.com/docs/API_Reference/Web_API/mail.html
      def deliver!(mail)
        parameters = settings.dup
        parameters.delete(:return_response)
        message = MultiMail::Message::SendGrid.new(mail).to_sendgrid_hash.merge(parameters)

        connection = Faraday.new do |conn|
          conn.request :multipart
          conn.request :url_encoded
        end

        response = connection.post('https://sendgrid.com/api/mail.send.json', message)

        body = JSON.load(response.body)

        unless response.status == 200
          raise body.inspect # @todo
        end

        if settings[:return_response]
          response
        else
          self
        end
      end
    end
  end
end
