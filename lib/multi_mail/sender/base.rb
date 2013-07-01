module MultiMail
  module Sender
    # Abstract class for outgoing email services.
    #
    # The `deliver!` instance method must be implemented in sub-classes.
    module Base
      def self.included(subclass)
        subclass.class_eval do
          extend MultiMail::Sender::Base::ClassMethods
        end
      end

      attr_accessor :settings

      # Delivers a message.
      #
      # @param [Mail::Message] mail a message
      def deliver!(mail)
        raise NotImplementedError
      end

      # @see https://github.com/wildbit/postmark-gem/blob/master/lib/postmark/message_extensions/mail.rb
      module ClassMethods
        def html?(message)
          !!message.content_type && message.content_type.include?('text/html')
        end

        def html_part(message)
          if message.html_part
            message.html_part.body.decoded
          elsif html?(message)
            message.body.decoded
          end
        end

        def text_part(message)
          if message.text_part
            message.text_part.body.decoded
          elsif !html?(message)
            message.body.decoded
          end
        end
      end
    end
  end
end
