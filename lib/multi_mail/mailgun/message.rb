module MultiMail
  module Message
    # @see http://documentation.mailgun.com/api-sending.html
    class Mailgun < MultiMail::Message::Base
      # Returns the message headers in Mailgun format.
      #
      # @return [Multimap] the message headers in Mailgun format
      def mailgun_headers
        hash = Multimap.new
        header_fields.each do |field|
          key = field.name.downcase
          unless %w(from to cc bcc subject tag).include?(key)
            hash["h:#{field.name}"] = field.value
          end
        end
        hash
      end

      # Returns the message's attachments in Mailgun format.
      #
      # @return [Multimap] the attachments in Mailgun format
      # @see http://documentation.mailgun.com/user_manual.html#inline-image
      def mailgun_attachments
        hash = Multimap.new
        attachments.each do |attachment|
          key = attachment.content_type.start_with?('image/') ? 'inline' : 'attachment'
          hash[key] = Faraday::UploadIO.new(StringIO.new(attachment.body.decoded), attachment.content_type, attachment.filename)
        end
        hash
      end

      # Returns the message as parameters to POST to Mailgun.
      #
      # @return [Hash] the message as parameters to POST to Mailgun
      # @see http://documentation.mailgun.com/user_manual.html#tagging
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

        tags.each do |tag|
          hash['o:tag'] = tag
        end

        normalize(hash.merge(mailgun_attachments).merge(mailgun_headers).to_hash)
      end
    end
  end
end
