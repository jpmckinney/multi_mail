module MultiMail
  module Message
    # @see http://sendgrid.com/docs/API_Reference/Web_API/mail.html
    class SendGrid < MultiMail::Message::Base
      # Returns the message headers in SendGrid format.
      #
      # @return [Hash] the message headers in SendGrid format
      def sendgrid_headers
        hash = {}
        header_fields.each do |field|
          key = field.name.downcase
          unless %w(to subject from bcc reply-to date).include?(key)
            # The JSON must not contain integers.
            hash[field.name] = field.value.to_s
          end
        end
        hash
      end

      # Returns the message's attachments in SendGrid format.
      #
      # @return [Hash] the attachments in SendGrid format
      def sendgrid_files
        hash = {}
        attachments.map do |attachment|
          # File contents must be part of the multipart HTTP POST.
          # @see http://sendgrid.com/docs/API_Reference/Web_API/mail.html
          hash[attachment.filename] = Faraday::UploadIO.new(StringIO.new(attachment.body.decoded), attachment.content_type, attachment.filename)
        end
        hash
      end

      # Returns the attachments' content IDs in SendGrid format.
      #
      # @return [Hash] the content IDs in SendGrid format
      def sendgrid_content
        hash = {}
        attachments.each do |attachment|
          if attachment.content_type.start_with?('image/')
            # Mirror Mailgun behavior for naming inline attachments.
            # @see http://documentation.mailgun.com/user_manual.html#inline-image
            hash[attachment.filename] = attachment.filename
          end
        end
        hash
      end

      # Returns the message as parameters to POST to SendGrid.
      #
      # @return [Hash] the message as parameters to POST to SendGrid
      def to_sendgrid_hash
        headers = sendgrid_headers

        hash = {
          'to'       => to.to_a,
          'toname'   => to && self[:to].display_names.to_a,
          'subject'  => subject,
          'text'     => body_text,
          'html'     => body_html,
          'from'     => from && from.first,
          'bcc'      => bcc.to_a,
          'fromname' => from && self[:from].display_names.first,
          'replyto'  => reply_to && reply_to.first,
          'date'     => date && Time.parse(date.to_s).rfc2822, # Ruby 1.8.7
          'files'    => sendgrid_files,
          'content'  => sendgrid_content,
          'headers'  => headers.empty? ? nil : JSON.dump(headers),
        }

        normalize(hash)
      end
    end
  end
end
