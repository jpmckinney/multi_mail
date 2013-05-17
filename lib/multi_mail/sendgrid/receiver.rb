module MultiMail
  module Receiver
    class SendGrid < MultiMail::Service
      include MultiMail::Receiver::Base

      def transform(params)
        this = self

        message = Mail.new do
          #there may be a cleaner way to do this, perhaps using multimap,
          #but I was unable to do use it because the fields have to be split
          #by the colon, as params['headers'] is just a string
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

      def spam?(message)
        message['spam_score'].to_s.to_i > 5
      end
    end
  end
end
