module MultiMail
  module Message
    # @see http://developer.postmarkapp.com/developer-build.html#message-format
    class Postmark < MultiMail::Message::Base
      # Returns the message headers in Postmark format.
      #
      # @return [Array<Hash>] the message headers in Postmark format
      def postmark_headers
        array = []
        header_fields.each do |field|
          key = field.name.downcase
          # @see https://github.com/wildbit/postmark-gem/blob/master/lib/postmark/message_extensions/mail.rb#L74
          # @see https://github.com/wildbit/postmark-gem/pull/36#issuecomment-22298955
          unless %w(from to cc bcc reply-to subject tag content-type date).include?(key) || (Array === field.value && field.value.size > 1)
            array << {'Name' => field.name, 'Value' => field.value}
          end
        end
        array
      end

      # Returns the message's attachments in Postmark format.
      #
      # @return [Array<Hash>] the attachments in Postmark format
      # @see http://developer.postmarkapp.com/developer-build.html#attachments
      def postmark_attachments
        attachments.map do |attachment|
          hash = {
            'ContentType' => attachment.content_type,
            'Name'        => attachment.filename,
            'Content'     => Base64.encode64(attachment.body.decoded)
          }
          if attachment.content_type.start_with?('image/')
            hash['ContentID'] = attachment.filename
          end
          hash
        end
      end

      # Returns the message as parameters to POST to Postmark.
      #
      # @return [Hash] the message as parameters to POST to Postmark
      def to_postmark_hash
        hash = {}

        %w(from subject).each do |field|
          if self[field]
            hash[postmark_key(field)] = self[field].value
          end
        end

        %w(to cc bcc reply_to).each do |field|
          if self[field]
            value = self[field].value
            hash[postmark_key(field)] = value.respond_to?(:join) ? value.join(', ') : value
          end
        end

        hash['TextBody']    = body_text
        hash['HtmlBody']    = body_html
        hash['Headers']     = postmark_headers
        hash['Attachments'] = postmark_attachments
        hash['Tag']         = tags.first

        normalize(hash)
      end

      private

      def postmark_key(string)
        string.downcase.split(/[_-]/).map(&:capitalize).join
      end
    end
  end
end
