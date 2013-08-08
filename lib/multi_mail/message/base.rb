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

      def tags
        if self['tag']
          if self['tag'].respond_to?(:map)
            self['tag'].map do |field|
              field.value
            end
          else
            [self['tag'].value]
          end
        else
          []
        end
      end

    private

      def normalize(hash)
        hash.delete_if do |_,value|
          value.nil? || value.empty? || Array === value && value.all?{|v| v.nil?}
        end

        hash.keys.each do |key| # based on Hash#symbolize_keys! from Rails
          hash[(key.to_sym rescue key) || key] = hash.delete(key)
        end

        hash
      end
    end
  end
end
