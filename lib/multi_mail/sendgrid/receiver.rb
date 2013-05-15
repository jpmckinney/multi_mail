module MultiMail
  module Receiver
    class SendGrid < MultiMail::Service
      include MultiMail::Receiver::Base

      requires :sendgrid_username
      requires :sendgrid_password
      recognizes :http_post_format
      attr_reader :http_post_format

      def transform(params)
        message = Mail.new do 

          headers params['headers']

          # The following are redundant with `with params['headers']
          #
          # from    params['from']
          # sender  params['sender']
          # to      params['recipient']
          # subject params['subject']
          envelope params['envelope']
          subject params['subject']


          1.upto(params['attachments']) do |i|
            key = 'attachment#{i}'
            add_file(:filename => params[key]['Name'], :content => params[key]['Content'])
          end


          body params['text']
          html_part do
            content_type 'text/html; charset=UTF-8'
            body params['html']
          end if params['html']
        end        
      end

      def spam?
        
      end
    end
  end
end


