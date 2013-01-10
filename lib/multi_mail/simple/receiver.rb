module MultiMail
  module Receiver
    class Simple < MultiMail::Service
      include MultiMail::Receiver::Base
      # Transforms the content of a simple webhook into a list of messages.
      #
      # @param [Hash] params the content of the webhook
      # @return [Array<Mail::Message>] messages
      def transform(params)
        [Mail.new(params['message'])]
      end
    end
  end
end