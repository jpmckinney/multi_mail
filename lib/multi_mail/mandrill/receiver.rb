module MultiMail
  module Receiver
    # Mandrill's incoming email receiver.
    class Mandrill < MultiMail::Service
      include MultiMail::Receiver::Base

      # @return [String] the Mandrill API key
      requires :mandrill_api_key

      # @return [Float] the minimum SpamAssassin score to be spam
      recognizes :spamassassin_threshold

      # Initializes a Mandrill incoming email receiver.
      #
      # @param [Hash] options required and optional arguments
      # @option opts [String] :mandrill_api_key a Mandrill API key
      def initialize(options = {})
        super
        @mandrill_api_key = options[:mandrill_api_key]
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
      def transform(params)
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

            html_part do
              content_type 'text/html; charset=UTF-8' # @todo unsure about charset
              body msg['html']
            end

            msg['attachments'].each do |attachment|
              add_file(:filename => attachment['name'], :content => attachment['content'])
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

          # Re-use Mailgun headers.
          message['X-Mailgun-SScore'] = msg['spam_report']['score']
          message['X-Mailgun-Spf'] = msg['spf']['result']

          message
        end
      end

      # Returns whether a message is spam.
      #
      # @param [Mail::Message] message a message
      # @return [Boolean] whether the message is spam
      def spam?(message)
        message.key?('X-Mailgun-SScore') && message['X-Mailgun-SScore'].value.to_f > @spamassassin_threshold
      end
    end
  end
end
