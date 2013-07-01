module MultiMail
  module Receiver
    class Simple < MultiMail::Service
      include MultiMail::Receiver::Base

      # Expects a raw email message parsable by the Mail gem.
      #
      # @param [Hash] params the content of the webhook
      # @return [Array<Mail::Message>] messages
      def transform(params)
        [Mail.new(params)]
      end
    end
  end
end