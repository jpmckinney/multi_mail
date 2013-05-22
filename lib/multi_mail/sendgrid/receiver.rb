module MultiMail
  module Receiver
    # SendGrid's incoming email receiver
    class SendGrid < MultiMail::Service
      include MultiMail::Receiver::Base
      # Initializes a SendGrid incoming email receiver
      #
      # @param [Hash] options required and optional arguments
      # @option option [Float] :spamassassin_threshold the Spamassassin score
      # needed to flag a message as spam
      def initialize(options = {})
        super
        @spamassassin_threshold = options[:spamassassin_threshold] || 5
      end

      # Transforms the content of SendGrid's webook into a list of messages
      # @param [Hash] params the content of Mandrill's webhook
      # @return [Array<Mail::Messages>] messages
      # @see http://sendgrid.com/docs/API_Reference/Webhooks/parse.html
      def transform(params)
        # Mail loses self
        this = self
        message = Mail.new do

          headers = {}
          params['headers'].split("\n").each do |h|
            headers[h.split(':')[0]] = h.split(':').drop(1).join(':').strip()
          end
          headers['spam_score'] = params['spam_score']
          headers headers

          # The following are redundant with `with params['headers']
          #
          # from    params['from']
          # sender  params['sender']
          # to      params['recipient']
          # subject params['subject']

          subject params['subject']
          
          text_part do
            content_type 'text/plain'
            body params['text']
          end

          html_part do
            content_type 'text/html; charset=UTF-8'
            body params['html']
          end if params['html']

          1.upto(params['attachments'].to_i) do |i|
            add_file(this.class.add_file_arguments(params["attachment#{i}"]))
          end
        end
        [message]
      end

      # Returns whether a message is spam.
      #
      # @param [Mail::Message] message a message
      # @return [Boolean] whether the message is spam
      def spam?(message)
        message['spam_score'].to_s.to_f > @spamassassin_threshold
      end
    end
  end
end
