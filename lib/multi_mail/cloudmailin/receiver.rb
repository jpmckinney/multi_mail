module MultiMail
  module Receiver
    class Cloudmailin < MultiMail::Service
      include MultiMail::Receiver::Base

      #requires :

      # @param [Hash] options required and optional arguments
      def initialize(options = {})
        super
      end

      # @param [Hash] params the content of Cloudmailin's webhook
      # @return [Boolean] whether the request originates from Cloudmailin
      # @see http://docs.cloudmailin.com/receiving_email/securing_your_email_url_target/
      def valid?(params)
        true
      end

      # @param [Hash] params the content of Cloudmailin's webhook
      # @return [Array<Mail::Message>] messages
      def transform(params)
        Mail.new do
        end
      end

      # @param [Mail::Message] message a message
      # @return [Boolean] whether the message is spam
      def spam?(message)
        false
      end
    end
  end
end
