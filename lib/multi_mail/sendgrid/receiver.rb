module MultiMail
  module Receiver
    # SendGrid's incoming email receiver.
    class SendGrid < MultiMail::Service
      include MultiMail::Receiver::Base
      # Initializes a SendGrid incoming email receiver.
      #
      # @param [Hash] options required and optional arguments
      # @option option [Float] :spamassassin_threshold the Spamassassin score
      #   needed to flag a message as spam
      def initialize(options = {})
        super
        @spamassassin_threshold = options[:spamassassin_threshold] || 5
      end

      # Transforms the content of SendGrid's webook into a list of messages.
      #
      # @param [Hash] params the content of Mandrill's webhook
      # @return [Array<Mail::Messages>] messages
      # @see http://sendgrid.com/docs/API_Reference/Webhooks/parse.html
      def transform(params)
        # Make variables available to the `encode` method.
        @params = params
        @charsets = JSON.parse(params['charsets'])

        # Mail changes `self`.
        this = self

        message = Mail.new do
          # SendGrid includes a `charsets` parameter, which describes the
          # encodings of the `from`, `to`, `cc` and `subject` parameters, which
          # we don't need because we parse the headers directly.
          # @see http://sendgrid.com/docs/API_Reference/Webhooks/parse.html#-Character-Sets-and-Header-Decoding
          header params['headers']

          # The following are redundant with `headers`:
          #
          # from    params['from']
          # to      params['to']
          # cc      params['cc']
          # subject params['subject']

          text_part do
            body this.encode('text')
          end

          if params.key?('html')
            html_part do
              content_type 'text/html; charset=UTF-8'
              body this.encode('html')
            end
          end

          1.upto(params['attachments'].to_i) do |n|
            attachment = params["attachment#{n}"]
            add_file(this.class.add_file_arguments(attachment))
          end
        end

        # Extra SendGrid parameters. Discard
        %w(dkim SPF spam_report spam_score).each do |key|
          message[key] = params[key]
        end

        # Discard `envelope`, which contains `to` and `from`, and the
        # undocumented `attachment-info`.
        [message]
      end

      # Returns whether a message is spam.
      #
      # @param [Mail::Message] message a message
      # @return [Boolean] whether the message is spam
      def spam?(message)
        message['spam_score'] && message['spam_score'].value.to_f > 5
      end

      def encode(key)
        if @charsets.key?(key)
          if @params[key].respond_to?(:force_encoding)
            @params[key].force_encoding(@charsets[key]).encode('UTF-8')
          else
            Iconv.conv('UTF-8', @charsets[key], @params[key])
          end
        else
          @params[key]
        end
      end
    end
  end
end
