module MultiMail
  module Receiver
    # Abstract class for incoming email receivers.
    #
    # The `transform` instance method must be implemented in sub-classes. The
    # `valid?` and `spam?` instance methods may be implemented in sub-classes.
    module Base
      def self.included(subclass)
        subclass.class_eval do
          extend MultiMail::Receiver::Base::ClassMethods
        end
      end

      # Ensures a request is authentic, parses it into a params hash, and
      # transforms it into a list of messages.
      #
      # @param [String,Hash] raw raw POST data or a params hash
      # @return [Array<Mail::Message>] messages
      # @raise [ForgedRequest] if the request is not authentic
      def process(raw)
        params = self.class.parse(raw)
        if valid?(params)
          transform(params)
        else
          raise ForgedRequest
        end
      end

      # Returns whether a request is authentic.
      #
      # @param [Hash] params the content of the provider's webhook
      # @return [Boolean] whether the request is authentic
      def valid?(params)
        true
      end

      # Transforms the content of a provider's webhook into a list of messages.
      #
      # @param [Hash] params the content of the provider's webhook
      # @return [Array<Mail::Message>] messages
      def transform(params)
        raise NotImplementedError
      end

      # Returns whether a message is spam.
      #
      # @param [Mail::Message] message a message
      # @return [Boolean] whether the message is spam
      def spam?(message)
        false
      end

      module ClassMethods
        # Parses raw POST data into a params hash.
        #
        # @param [String,Hash] raw raw POST data or a params hash
        # @raise [ArgumentError] if the argument is not a string or a hash
        def parse(raw)
          case raw
          when String
            params = CGI.parse(raw)
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
