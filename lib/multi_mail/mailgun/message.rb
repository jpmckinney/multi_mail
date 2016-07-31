module MultiMail
  module Message
    # @see http://documentation.mailgun.com/api-sending.html
    class Mailgun < MultiMail::Message::Base
      attr_accessor :stripped_text, :stripped_signature, :stripped_html, :content_id_map

      # Returns the message headers in Mailgun format.
      #
      # @return [Hash] the message headers in Mailgun format
      def mailgun_headers
        map = Multimap.new
        hash = Hash.new

        header_fields.each do |field|
          key = field.name.downcase
          unless %w(from to cc bcc subject tag).include?(key)
            if key == 'reply-to'
              hash["h:#{field.name}"] = field.value
            else
              map["h:#{field.name}"] = field.value
            end
          end
        end

        map.to_hash.merge(hash)
      end

      # Returns the message's attachments in Mailgun format.
      #
      # @return [Multimap] the attachments in Mailgun format
      # @see http://documentation.mailgun.com/user_manual.html#inline-image
      def mailgun_attachments
        map = Multimap.new
        attachments.each do |attachment|
          key = attachment.content_type.start_with?('image/') ? 'inline' : 'attachment'
          map[key] = Faraday::UploadIO.new(StringIO.new(attachment.body.decoded), attachment.content_type, attachment.filename)
        end
        map
      end

      # Returns the message as parameters to POST to Mailgun.
      #
      # @return [Hash] the message as parameters to POST to Mailgun
      # @see http://documentation.mailgun.com/user_manual.html#tagging
      def to_mailgun_hash
        map = Multimap.new
        hash = Hash.new

        %w(from subject).each do |field|
          if self[field]
            map[field] = self[field].value
          end
        end

        %w(to cc bcc).each do |field|
          if self[field]
            if self[field].value.respond_to?(:each)
              self[field].value.each do |value|
                map[field] = value
              end
            else
              map[field] = self[field].value
            end
          end
        end

        if body_text && !body_text.empty?
          map['text'] = body_text
        end
        if body_html && !body_html.empty?
          map['html'] = body_html
        end

        tags.each do |tag|
          map['o:tag'] = tag
        end

        normalize(map.merge(mailgun_attachments).to_hash.merge(mailgun_headers).merge(hash))
      end
    end
  end
end
