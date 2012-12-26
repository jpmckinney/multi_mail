module MultiMail
  module Receiver
    # Abstract class for incoming email services.
    #
    # The `transform` instance method must be implemented in sub-classes. The
    # `valid?` and `spam?` instance methods may be implemented in sub-classes.
    module Base
      def self.included(subclass)
        subclass.class_eval do
          extend MultiMail::Receiver::Base::ClassMethods
        end
      end

      # @param [String,Hash] raw raw POST data or a params hash
      # @return [Mail::Message] a message
      # @raises [ForgedRequest] if the request is not authentic
      def process(raw)
        params = self.class.parse raw
        if valid? params
          transform params
        else
          raise ForgedRequest
        end
      end

      # @param [Hash] params the content of the provider's webhook
      # @return [Boolean] whether the request is authentic
      def valid?(params)
        true
      end

      # @param [Hash] params the content of the provider's webhook
      # @return [Mail::Message] a message
      def transform(params)
        raise NotImplementedError
      end

      # @param [Mail::Message] message a message
      # @return [Boolean] whether the message is spam
      def spam?(message)
        false
      end

      module ClassMethods
        # @param [String,Hash] raw raw POST data or a params hash
        def parse(raw)
          case raw
          when String
            params = CGI.parse raw
            params.each do |key,value|
              if Array === value && value.size == 1
                params[key] = value.first
              end
            end
            params
          when Hash
            raw
          else
            raise ArgumentError, "Can't handle #{raw.class.name} input"
          end
        end
      end
    end
  end
end
