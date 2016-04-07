module MultiMail
  module Message
    # @see http://documentation.mailgun.com/api-sending.html
    class Mailgun < MultiMail::Message::Base
      attr_accessor :stripped_text, :stripped_signature, :stripped_html, :content_id_map

      # Returns the message headers in Mailgun format.
      #
      # @return [Multimap] the message headers in Mailgun format
      def mailgun_headers
        mm = Multimap.new
        header_fields.each do |field|
          key = field.name.downcase
          unless %w(from to cc bcc subject tag reply-to).include?(key)
            mm["h:#{field.name}"] = field.value
          end
        end
        mm.instance_variable_get('@hash')['h:Reply-To'] = self['Reply-To'].value if self['Reply-To']
        mm
      end

      # Returns the message's attachments in Mailgun format.
      #
      # @return [Multimap] the attachments in Mailgun format
      # @see http://documentation.mailgun.com/user_manual.html#inline-image
      def mailgun_attachments
        mm = Multimap.new
        attachments.each do |attachment|
          key = attachment.content_type.start_with?('image/') ? 'inline' : 'attachment'
          mm[key] = Faraday::UploadIO.new(StringIO.new(attachment.body.decoded), attachment.content_type, attachment.filename)
        end
        mm
      end

      # Returns the message as parameters to POST to Mailgun.
      #
      # @return [Hash] the message as parameters to POST to Mailgun
      # @see http://documentation.mailgun.com/user_manual.html#tagging
      def to_mailgun_hash
        mm = Multimap.new
        hash = Hash.new

        %w(from subject).each do |field|
          if self[field]
            mm[field] = self[field].value
          end
        end

        %w(to cc bcc).each do |field|
          if self[field]
            if self[field].value.respond_to?(:each)
              self[field].value.each do |value|
                mm[field] = value
              end
            else
              mm[field] = self[field].value
            end
          end
        end

        # there may be others we want to do this with
        %w(h:Reply-To).each do |field|
          if self[field]
            hash[field] = self[field].value
          end
        end

        if body_text && !body_text.empty?
          mm['text'] = body_text
        end
        if body_html && !body_html.empty?
          mm['html'] = body_html
        end

        tags.each do |tag|
          mm['o:tag'] = tag
        end

        normalize(mm.to_hash.merge(mailgun_attachments).merge(mailgun_headers).merge(hash))
      end
    end
  end
end
