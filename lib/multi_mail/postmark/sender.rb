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

      # Initializes a Postmark outgoing email sender.
      #
      # @param [Hash] options required and optional arguments
      # @option options [String] :api_key a Postmark API key
      # @see https://github.com/wildbit/postmark-gem#communicating-with-the-api
      def initialize(options = {})
        raise ArgumentError, "Missing required arguments: :api_key" unless options[:api_key]
        @settings = options.dup
      end

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
