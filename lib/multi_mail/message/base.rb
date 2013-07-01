module MultiMail
  module Message
    class Base < Mail::Message
      # @see https://github.com/wildbit/postmark-gem/blob/master/lib/postmark/message_extensions/mail.rb
      def html?
        !!content_type && content_type.include?('text/html')
      end

      def body_html
        if html_part
          html_part.body.decoded
        elsif html?
          body.decoded
        end
      end

      def body_text
        if text_part
          text_part.body.decoded
        elsif !html?
          body.decoded
        end
      end
    end
  end
end
