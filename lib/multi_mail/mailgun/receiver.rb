module MultiMail
  module Receiver
    class Mailgun < MultiMail::Service
      include MultiMail::Receiver::Base

      requires :mailgun_api_key

      # Initializes a Mailgun incoming email receiver.
      #
      # @param [Hash] options required and optional arguments
      # @option opts [String] :mailgun_api_key a Mailgun API key
      def initialize(options = {})
        super
        @mailgun_api_key = options[:mailgun_api_key]
      end

      # Returns whether a request originates from Mailgun.
      #
      # @param [Hash] params the content of Mailgun's webhook
      # @return [Boolean] whether the request originates from Mailgun
      # @raises [KeyError] if the request is missing parameters
      # @see http://documentation.mailgun.net/user_manual.html#securing-webhooks
      def valid?(params)
        params.fetch('signature') == OpenSSL::HMAC.hexdigest(
          OpenSSL::Digest::Digest.new('sha256'), @mailgun_api_key,
          '%s%s' % [params.fetch('timestamp'), params.fetch('token')])
      end

      # Transforms the content of Mailgun's webhook into a list of messages.
      #
      # @param [Hash] params the content of Mailgun's webhook
      # @return [Array<Mail::Message>] messages
      # @note Mailgun sends the message headers both individually and in the
      #   `message-headers` parameter. Only `message-headers` is documented.
      # @todo parse attachments properly
      def transform(params)
        headers = Multimap.new
        JSON.parse(params['message-headers']).each do |key,value|
          headers[key] = value
        end

        message = Mail.new do
          headers headers

          # The following are redundant with `message-headers`:
          #
          # from    params['from']
          # sender  params['sender']
          # to      params['recipient']
          # subject params['subject']

          text_part do
            body params['body-plain']
          end

          html_part do
            content_type 'text/html; charset=UTF-8'
            body params['body-html']
          end
        end

        # Extra Mailgun parameters.
        [ 'stripped-text',
          'stripped-signature',
          'stripped-html',
          'attachment-count',
          'attachment-x',
          'content-id-map',
        ].each do |key|
          if !params[key].nil? && !params[key].empty?
            message[key] = params[key]
          end
        end

        [message]
      end

      # Returns whether a message is spam.
      #
      # @param [Mail::Message] message a message
      # @return [Boolean] whether the message is spam
      # @see http://documentation.mailgun.net/user_manual.html#spam-filter
      # @note You must enable spam filtering for each domain in Mailgun's [Control
      #   Panel](https://mailgun.net/cp/domains).
      # @note We may also inspect `X-Mailgun-SScore` and `X-Mailgun-Spf`, whose
      #   possible values are "Pass", "Neutral", "Fail" and "SoftFail".
      def spam?(message)
        message['X-Mailgun-Sflag'].value == 'Yes'
      end
    end
  end
end
