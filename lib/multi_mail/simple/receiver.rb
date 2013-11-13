module MultiMail
  module Receiver
    # A simple incoming email receiver.
    class Simple
      include MultiMail::Receiver::Base

      recognizes :secret

      # Initializes a simple incoming email receiver.
      #
      # @param [Hash] options required and optional arguments
      # @option options [String] :secret a secret key
      def initialize(options = {})
        super
        @secret = options[:secret]
      end

      # Returns whether a request is authentic.
      #
      # @param [Hash] params the content of the webhook
      # @return [Boolean] whether the request is authentic
      # @raise [IndexError] if the request is missing parameters
      def valid?(params)
        if @secret
          params.fetch('signature') == signature(params)
        else
          super
        end
      end

      # Expects a raw email message parsable by the Mail gem.
      #
      # @param [Hash] params the content of the webhook
      # @return [Array<Mail::Message>] messages
      def transform(params)
        [Mail.new(params)]
      end

      def signature(params)
        data = "#{params.fetch('timestamp')}#{params.fetch('token')}"
        OpenSSL::HMAC.hexdigest('sha256', @secret, data)
      end
    end
  end
end
