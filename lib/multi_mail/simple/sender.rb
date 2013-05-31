module MultiMail
  module Sender
    class Simple < MultiMail::Service
      include MultiMail::Sender::Base

      #requires :

      # @param [Hash] values required and optional arguments
      def initialize(values)
        super
        # @todo Set API keys, etc.
      end

      # @param [Mail::Message] mail a message
      def deliver!(mail)
        smtp_from, smtp_to, message = check_delivery_params(mail)
        # @todo Send API requests
      end
    end
  end
end
