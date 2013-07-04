module MultiMail
  module Message
    # @see http://documentation.mailgun.com/api-sending.html
    class Mailgun < MultiMail::Message::Base
      def mailgun_attachments
        hash = Multimap.new
        attachments.each do |attachment|
          hash['attachment'] = Faraday::UploadIO.new(StringIO.new(attachment.body.decoded), attachment.content_type, attachment.filename)
        end
        hash
      end

      def mailgun_headers
        hash = Multimap.new
        header_fields.each do |field|
          key = field.name.downcase
          unless %w(from to cc bcc subject message-id).include?(key)
            hash["h:#{field.name}"] = field.value.to_s
          end
        end
        hash
      end

      def to_mailgun_hash
        hash = Multimap.new

        %w(from subject).each do |field|
          if self[field]
            hash[field] = self[field].value
          end
        end

        %w(to cc bcc).each do |field|
          if self[field]
            if self[field].value.respond_to?(:each)
              self[field].value.each do |value|
                hash[field] = value
              end
            else
              hash[field] = self[field].value
            end
          end
        end

        if body_text && !body_text.empty?
          hash['text'] = body_text
        end
        if body_html && !body_html.empty?
          hash['html'] = body_html
        end

        hash.merge(mailgun_attachments).merge(mailgun_headers)
      end
    end
  end
end
