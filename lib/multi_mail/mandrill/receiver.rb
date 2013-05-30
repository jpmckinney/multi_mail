module MultiMail
  module Receiver
    # Mandrill's incoming email receiver.
    #
    # Mandrill uses an HTTP header to ensure a request originates from Mandrill.
    #
    # @see http://help.mandrill.com/entries/23704122-Authenticating-webhook-requests
    class Mandrill < MultiMail::Service
      include MultiMail::Receiver::Base

      recognizes :spamassassin_threshold, :mandrill_webhook_key, :mandrill_webhook_url

      # Initializes a Mandrill incoming email receiver.
      #
      # @param [Hash] options required and optional arguments
      # @option option [Float] :spamassassin_threshold the SpamAssassin score
      #   needed to flag a message as spam
      def initialize(options = {})
        super
        @spamassassin_threshold = options[:spamassassin_threshold] || 5
        @mandrill_webhook_key = options[:mandrill_webhook_key]
        @mandrill_webhook_url = options[:mandrill_webhook_url]
      end

      # Returns whether a request originates from Mandrill.
      #
      # @param [Hash] params the content of Mandrill's webhook
      # @return [Boolean] whether the request originates from Mailgun
      # @raise [IndexError] if the request is missing parameters
      # @see http://help.mandrill.com/entries/23704122-Authenticating-webhook-requests
      def valid?(params)
        if @mandrill_webhook_url && @mandrill_webhook_key
          params.fetch('env').fetch('HTTP_X_MANDRILL_SIGNATURE') == signature(params)
        else
          super
        end
      end

      # Transforms the content of Mandrill's webhook into a list of messages.
      #
      # @param [Hash] params the content of Mandrill's webhook
      # @return [Array<Mail::Message>] messages
      # @see http://help.mandrill.com/entries/22092308-What-is-the-format-of-inbound-email-webhooks-
      def transform(params)
        # JSON is necessarily UTF-8.

        JSON.parse(params['mandrill_events']).select do |event|
          event.fetch('event') == 'inbound'
        end.map do |event|
          msg = event['msg']

          # Mail changes `self`.
          headers = self.class.multimap(msg['headers'])
          this = self

          message = Mail.new do
            headers headers

            # The following are redundant with `message-headers`:
            #
            # address = Mail::Address.new(msg['from_email'])
            # address.display_name = msg['from_name']
            #
            # from    address.format
            # to      msg['to'].flatten.compact
            # subject msg['subject']

            text_part do
              body msg['text']
            end

            # If an email contains multiple HTML parts, Mandrill will only
            # include the first HTML part in its `html` parameter. We therefore
            # parse its `raw_msg` parameter to set the HTML part correctly.
            html = this.class.condense(Mail.new(msg['raw_msg'])).parts.find do |part|
              part.content_type == 'text/html; charset=UTF-8'
            end

            if html
              html_part do
                content_type 'text/html; charset=UTF-8'
                body html.body.decoded
              end
            elsif msg.key?('html')
              html_part do
                content_type 'text/html; charset=UTF-8'
                body msg['html']
              end
            end

            if msg.key?('attachments')
              msg['attachments'].each do |_,attachment|
                add_file(:filename => attachment['name'], :content => attachment['content'])
              end
            end
          end



          # Extra Mandrill parameters. Discard `sender` and `tags`, which are
          # null according to the docs, `matched_rules` within `spam_report`,
          # and `detail` within `spf`, which is just a human-readable version of
          # `result`.
          message['ts']                = event['ts']
          message['email']             = msg['email']
          message['dkim-signed']       = msg['dkim']['signed'].to_s
          message['dkim-valid']        = msg['dkim']['valid'].to_s
          message['spam_report-score'] = msg['spam_report']['score']
          message['spf-result']        = msg['spf']['result']
          message
        end
      end

      # Returns whether a message is spam.
      #
      # @param [Mail::Message] message a message
      # @return [Boolean] whether the message is spam
      def spam?(message)
        message['spam_report-score'] && message['spam_report-score'].value.to_f > @spamassassin_threshold
      end

    private

      def signature(params)
        data = @mandrill_webhook_url
        params.sort.each do |key,value|
          unless key == 'env'
            data += "#{key}#{value}"
          end
        end
        Base64.encode64(OpenSSL::HMAC.digest('sha1', @mandrill_webhook_key, data)).strip
      end
    end
  end
end
