module MultiMail
  module Message
    # @see http://sendgrid.com/docs/API_Reference/Web_API/mail.html
    class SendGrid < MultiMail::Message::Base
      def sendgrid_files
        attachments.map do |attachment|
          Faraday::UploadIO.new(StringIO.new(attachment.body.decoded), attachment.content_type, attachment.filename)
        end
      end

      def sendgrid_content
        attachments.map do |attachment|
          attachment.cid
        end
      end

      # The JSON must not contain integers.
      def sendgrid_headers
        headers = {}
        header_fields.each do |field|
          key = field.name.downcase
          unless %w(bcc date from reply-to subject to).include?(key)
            headers[field.name] = field.value.to_s
          end
        end
        headers
      end

      def to_sendgrid_hash
        headers = sendgrid_headers

        { 'to'       => to.to_a,
          'toname'   => to && self[:to].display_names.to_a,
          'subject'  => subject,
          'text'     => body_text,
          'html'     => body_html,
          'from'     => from && from.first,
          'bcc'      => bcc.to_a,
          'fromname' => from && self[:from].display_names.first,
          'replyto'  => reply_to && reply_to.first,
          'date'     => date && date.rfc2822,
          'files'    => sendgrid_files,
          'content'  => sendgrid_content,
          'headers'  => headers.empty? ? nil : JSON.dump(headers),
        }.delete_if do |_,value|
          value.nil? || value.empty? || Array === value && value.all?{|v| v.nil?}
        end
      end
    end
  end
end
