module MultiMail
  module Receiver
    class SendGrid < MultiMail::Service
      include MultiMail::Receiver::Base

      requires :sendgrid_username
      requires :sendgrid_password
      recognizes :http_post_format
      attr_reader :http_post_format

      def initialize(options = {})
        super
        @sendgrid_username = options[:sendgrid_username]
        @sendgrid_password = options[:sendgrid_password]
        @http_post_format = options[:http_post_format]
      end

      def transform(params)
        attachments = 1.upto(params['attachments'].to_i).map do |num|
          attachment_from_params(params["attachment#{num}"])
        end

        @message = Mail.new do
          header params['headers']

          body params['text']

          html_part do
            content_type 'text/html; charset=UTF-8'
            body params['html']
          end if params['html']

          attachments.each do |attachment|
            add_file(attachment)
          end
        end
      end
    end
  end
end


