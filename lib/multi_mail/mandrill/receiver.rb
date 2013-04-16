module MultiMail
  module Receiver
    # Mandrill's incoming email receiver.
    class Mandrill < MultiMail::Service
      include MultiMail::Receiver::Base

      recognizes :spamassassin_threshold

      # Initializes a Mandrill incoming email receiver.
      #
      # @param [Hash] options required and optional arguments
      # @option option [Float] :spamassassin_threshold the SpamAssassin score
      #   needed to flag a message as spam
      def initialize(options = {})
        super
        @spamassassin_threshold = options[:spamassassin_threshold] || 5
      end

      # Returns whether a request is an inbound event.
      #
      # @param [Hash] params the content of Mandrill's webhook
      # @return [Boolean] whether the request is an inbound event
      def valid?(params)
        JSON.parse(params['mandrill_events']).all? do |event|
          event.fetch('event') == 'inbound'
        end
      end

      # Transforms the content of Mandrill's webhook into a list of messages.
      #
      # @param [Hash] params the content of Mandrill's webhook
      # @return [Array<Mail::Message>] messages
      # @see http://help.mandrill.com/entries/22092308-What-is-the-format-of-inbound-email-webhooks-
      def transform(params)
        # JSON is necessarily UTF-8.
        JSON.parse(params['mandrill_events']).map do |event|
          msg = event['msg']

          headers = Multimap.new
          msg['headers'].each do |key,value|
            if Array === value
              value.each do |v|
                headers[key] = v
              end
            else
              headers[key] = value
            end
          end

          message = Mail.new do
            headers headers

            # The following are redundant with `message-headers`:
            #
            # address = Mail::Address.new msg['from_email']
            # address.display_name = msg['from_name']
            #
            # from    address.format
            # to      msg['to'].flatten.compact
            # subject msg['subject']

            text_part do
              body msg['text']
            end

            if msg.key?('html')
              html_part do
                content_type 'text/html; charset=UTF-8'
                body msg['html']
              end
            end

            if msg.key?('attachments')
              msg['attachments'].each do |attachment|
                add_file(:filename => attachment['name'], :content => attachment['content'])
              end
            end
          end

          # Extra Mandrill parameters. Discard `sender` and `tags`, which are
          # null according to the docs, `matched_rules` within `spam_report`,
          # `detail` within `spf`, which is just a human-readable version of
          # `result`, and `raw_msg`.
          message['ts'] = event['ts']
          message['email'] = msg['email']
          message['dkim-signed'] = msg['dkim']['signed']
          message['dkim-valid'] = msg['dkim']['valid']
          message['spam_report-score'] = msg['spam_report']['score']
          message['spf-result'] = msg['spf']['result']

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
    end
  end
end
