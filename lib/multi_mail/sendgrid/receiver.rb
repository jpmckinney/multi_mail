module MultiMail
  module Receiver
    class SendGrid < MultiMail::Service
      include MultiMail::Receiver::Base

      def transform(params)
        this = self

        message = Mail.new do
          # SendGrid includes a `charsets` parameter, which describes the
          # encodings of the `from`, `to`, `cc` and `subject` parameters, which
          # we don't need because we parse the headers directly. It also
          # describes the encoding of the `text` and `html` parameters, which we
          # may want to use. An undocumented `attachment-info` parameter
          # describes the encodings of some of the attachments.
          # @see http://sendgrid.com/docs/API_Reference/Webhooks/parse.html#-Character-Sets-and-Header-Decoding
          header params['headers']

          # The following are redundant with `headers`:
          #
          # from    params['from']
          # to      params['to']
          # cc      params['cc']
          # subject params['subject']

          text_part do
            body params['text']
          end

          if params.key?('html')
            html_part do
              content_type 'text/html; charset=UTF-8'
              body params['html']
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

      def spam?(message)
        message['spam_score'] && message['spam_score'].value.to_f > 5
      end
    end
  end
end
