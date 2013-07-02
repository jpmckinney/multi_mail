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
        @settings = options
      end

      # Delivers a message via the Postmark API.
      #
      # @param [Mail::Message] mail a message
      # @see https://github.com/wildbit/postmark-gem#using-postmark-with-the-mail-library
      def deliver!(mail)
        mail.delivery_method Mail::Postmark, settings
        mail.deliver
      rescue ::Postmark::InvalidApiKeyError
        raise ArgumentError, "Missing required arguments: :api_key"
      end
    end
  end
end
