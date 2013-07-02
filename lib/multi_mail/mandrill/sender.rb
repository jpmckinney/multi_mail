begin
  require 'mandrill'
rescue LoadError
  raise 'The mandrill-api gem is not available. In order to use the Mandrill sender, you must: gem install mandrill-api'
end

require 'multi_mail/mandrill/message'

module MultiMail
  module Sender
    # Mandrill's outgoing mail sender.
    class Mandrill
      include MultiMail::Sender::Base

      attr_reader :api_key, :async, :ip_pool, :send_at

      # Initializes a Mandrill outgoing email sender.
      #
      # @param [Hash] options required and optional arguments
      # @option options [String] :api_key a Mandrill API key
      # @see https://mandrillapp.com/api/docs/index.ruby.html
      def initialize(options = {})
        settings         = options.dup
        @api_key         = settings.delete(:api_key)
        @async           = settings.delete(:async) || false
        @ip_pool         = settings.delete(:ip_pool)
        @send_at         = settings.delete(:send_at)
        @settings        = settings
      end

      # Delivers a message via the Mandrill API.
      #
      # @param [Mail::Message] mail a message
      # @see https://mandrillapp.com/api/docs/messages.ruby.html#method-send
      def deliver!(mail)
        parameters = settings.dup
        parameters.delete(:return_response)
        api_client = ::Mandrill::API.new(api_key)
        message    = MultiMail::Message::Mandrill.new(mail).to_mandrill_hash.merge(parameters)
        response   = api_client.messages.send(message, async, ip_pool, send_at)

        if settings[:return_response]
          response
        else
          self
        end
      rescue ::Mandrill::InvalidKeyError
        raise ArgumentError, "Invalid API key"
      rescue ::Mandrill::Error => e
        if e.message == 'You must provide a Mandrill API key'
          raise ArgumentError, "Missing required arguments: :api_key"
        else
          raise e
        end
      end
    end
  end
end
