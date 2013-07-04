begin
  require 'postmark'
rescue LoadError
  raise 'The postmark gem is not available. In order to use the Postmark sender, you must: gem install postmark'
end

module MultiMail
  module Sender
    # Postmark's outgoing mail sender.
    class Postmark
      include MultiMail::Sender::Base

      # @see https://github.com/wildbit/postmark-gem#communicating-with-the-api
      requires :api_key

      # Delivers a message via the Postmark API.
      #
      # @param [Mail::Message] mail a message
      # @see https://github.com/wildbit/postmark-gem#using-postmark-with-the-mail-library
      def deliver!(mail)
        mail.delivery_method Mail::Postmark, settings

        if settings[:return_response]
          mail.deliver!
        else
          mail.deliver
        end
      rescue ::Postmark::InvalidApiKeyError
        raise InvalidAPIKey
      rescue ::Postmark::InvalidMessageError
        raise InvalidMessage
      end
    end
  end
end
