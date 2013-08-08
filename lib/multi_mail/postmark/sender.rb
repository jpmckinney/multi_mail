require 'multi_mail/postmark/message'

module MultiMail
  module Sender
    # Postmark's outgoing mail sender.
    class Postmark
      include MultiMail::Sender::Base

      requires :api_key

      attr_reader :api_key

      # Initializes a Postmark outgoing email sender.
      #
      # @param [Hash] options required and optional arguments
      # @option options [String] :api_key a Postmark API key
      # @see http://developer.postmarkapp.com/developer-build.html#authentication-headers
      def initialize(options = {})
        super
        @api_key = settings.delete(:api_key)
      end

      # Delivers a message via the Postmark API.
      #
      # @param [Mail::Message] mail a message
      # @see http://developer.postmarkapp.com/developer-build.html
      # @see http://developer.postmarkapp.com/developer-build.html#http-response-codes
      # @see http://developer.postmarkapp.com/developer-build.html#api-error-codes
      def deliver!(mail)
        parameters = settings.dup
        parameters.delete(:return_response)
        message = MultiMail::Message::Postmark.new(mail).to_postmark_hash.merge(parameters)

        response = Faraday.post do |request|
          request.url 'https://api.postmarkapp.com/email'
          request.headers['Accept'] = 'application/json'
          request.headers['Content-Type'] = 'application/json'
          request.headers['X-Postmark-Server-Token'] = @api_key
          request.body = JSON.dump(message)
        end

        body = JSON.load(response.body)

        unless response.status == 200
          case body['ErrorCode']
          when 0
            raise InvalidAPIKey, body['Message']
          when 300
            case body['Message']
            when "Invalid 'From' value."
              raise MissingSender, body['Message']
            when 'Zero recipients specified'
              raise MissingRecipients, body['Message']
            when 'Provide either email TextBody or HtmlBody or both.'
              raise MissingBody, body['Message']
            else
              raise InvalidMessage, body['Message']
            end
          else
            raise InvalidRequest, body['Message']
          end
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
