module MultiMail
  module Receiver
    # Mailgun's incoming email receiver.
    class Mailgun < MultiMail::Service
      include MultiMail::Receiver::Base

      requires :mailgun_api_key
      recognizes :http_post_format

      # Initializes a Mailgun incoming email receiver.
      #
      # @param [Hash] options required and optional arguments
      # @option options [String] :mailgun_api_key a Mailgun API key
      # @option options [String] :http_post_format "parsed" or "raw"
      def initialize(options = {})
        super
        @mailgun_api_key = options[:mailgun_api_key]
        @http_post_format = options[:http_post_format]
      end

      # Returns whether a request originates from Mailgun.
      #
      # @param [Hash] params the content of Mailgun's webhook
      # @return [Boolean] whether the request originates from Mailgun
      # @raise [IndexError] if the request is missing parameters
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
      # @see http://documentation.mailgun.net/user_manual.html#mime-messages-parameters
      # @see http://documentation.mailgun.net/user_manual.html#parsed-messages-parameters
      def transform(params)
        case @http_post_format
        when 'parsed', '', nil
          headers = Multimap.new
          JSON.parse(params['message-headers']).each do |key,value|
            headers[key] = value
          end

          this = self
          message = Mail.new do
            headers headers

            # The following are redundant with `body-mime` in raw MIME format
            # and with `message-headers` in fully parsed format.
            #
            # from    params['from']
            # sender  params['sender']
            # to      params['recipient']
            # subject params['subject']
            #
            # Mailgun POSTs all MIME headers both individually and in
            # `message-headers`.

            text_part do
              body params['body-plain']
            end

            if params.key?('body-html')
              html_part do
                content_type 'text/html; charset=UTF-8'
                body params['body-html']
              end
            end

            if params.key?('attachment-count')
              1.upto(params['attachment-count'].to_i).each do |n|
                attachment = params["attachment-#{n}"]
                add_file(this.class.add_file_arguments(attachment))
              end
            end
          end

          # Extra Mailgun parameters.
          extra = [
            'stripped-text',
            'stripped-signature',
            'stripped-html',
            'content-id-map',
          ]

          # Non-plain, non-HTML body parts.
          extra += params.keys.select do |key|
            key[/\Abody-(?!html|plain)/]
          end

          extra.each do |key|
            if params.key?(key) && !params[key].empty?
              message[key] = params[key]
            end
          end

          [message]
        when 'raw'
          [Mail.new(params['body-mime'])]
        else
          raise ArgumentError, "Can't handle Mailgun #{@http_post_format} HTTP POST format"
        end
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
        message['X-Mailgun-Sflag'] && message['X-Mailgun-Sflag'].value == 'Yes'
      end
    end
  end
end
