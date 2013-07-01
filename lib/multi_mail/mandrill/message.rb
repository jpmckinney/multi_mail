module MultiMail
  module Message
    # @see https://mandrillapp.com/api/docs/messages.ruby.html#method-send
    class Mandrill < MultiMail::Message::Base
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

      # Mandrill only allows Reply-To and X-* headers for now.
      def mandrill_headers
        headers = {}
        header_fields.each do |field|
          key = field.name.downcase
          if key == 'reply-to' || key.start_with?('x-')
            headers[field.name] = field.value
          end
        end
        headers
      end

      def mandrill_attachments
        attachments.map do |attachment|
          {
            'type'    => attachment.content_type,
            'name'    => attachment.filename,
            'content' => Base64.encode64(attachment.body.decoded)
          }
        end
      end

      def to_mandrill_hash
        images, attachments = mandrill_attachments.partition do |attachment|
          attachment['type'].start_with?('image/')
        end

        { 'html'        => body_html,
          'text'        => body_text,
          'subject'     => subject,
          'from_email'  => from && from.first,
          'from_name'   => from && self[:from].display_names.first,
          'to'          => mandrill_to,
          'headers'     => mandrill_headers,
          'attachments' => attachments,
          'images'      => images,
        }.delete_if do |_,value|
          value.nil? || value.empty?
        end
      end
    end
  end
end
