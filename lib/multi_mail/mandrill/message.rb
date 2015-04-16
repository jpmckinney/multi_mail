module MultiMail
  module Message
    # @see https://mandrillapp.com/api/docs/messages.ruby.html#method-send
    class Mandrill < MultiMail::Message::Base
      attr_accessor :ts, :email, :dkim_signed, :dkim_valid, :spam_report_score, :spf_result

      # Returns the To header in Mandrill format.
      #
      # @return [Array<Hash>] the To header in Mandrill format
      def mandrill_to
        if to
          to.each_with_index.map do |value,index|
            {
              'email' => value,
              'name'  => self[:to].display_names[index]
            }
          end
        else
          []
        end
      end

      # Returns the message headers in Mandrill format.
      #
      # @return [Hash] the message headers in Mandrill format
      def mandrill_headers
        hash = {}
        header_fields.each do |field|
          key = field.name.downcase
          # Mandrill only allows Reply-To and X-* headers currently.
          # https://mandrillapp.com/api/docs/messages.ruby.html
          if key == 'reply-to' || key.start_with?('x-')
            hash[field.name] = field.value
          end
        end
        hash
      end

      # Returns the message's attachments in Mandrill format.
      #
      # @return [Array<Faraday::UploadIO>] the attachments in Mandrill format
      def mandrill_attachments
        attachments.map do |attachment|
          {
            'type'    => attachment.content_type,
            'name'    => attachment.filename,
            'content' => Base64.encode64(attachment.body.decoded)
          }
        end
      end

      # Returns the message as parameters to POST to Mandrill.
      #
      # @return [Hash] the message as parameters to POST to Mandrill
      def to_mandrill_hash
        images, attachments = mandrill_attachments.partition do |attachment|
          attachment['type'].start_with?('image/')
        end

        hash = {
          'html'        => body_html,
          'text'        => body_text,
          'subject'     => subject,
          'from_email'  => from && from.first,
          'from_name'   => from && self[:from].display_names.first,
          'to'          => mandrill_to,
          'headers'     => mandrill_headers,
          'attachments' => attachments,
          'images'      => images,
          'tags'        => tags,
        }

        normalize(hash)
      end
    end
  end
end
