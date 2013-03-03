module MultiMail
  module Receiver
    class Simple < MultiMail::Service
      include MultiMail::Receiver::Base
      # Expects the value of the "message" query string parameter to be a raw
      # email message parsable by the Mail gem.
      #
      # @param [Hash] params the content of the webhook
      # @return [Array<Mail::Message>] messages
      def transform(params)
        [Mail.new(params['message'])]
      end
    end
  end
end