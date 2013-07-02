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
        raise ArgumentError, "Missing required arguments: :api_key" unless options[:api_key]
        @settings = options.dup

        @api_key = settings.delete(:api_key)
        @async   = settings.delete(:async) || false
        @ip_pool = settings.delete(:ip_pool)
        @send_at = settings.delete(:send_at)
      end

      # Delivers a message via the Mandrill API.
      #
      # @param [Mail::Message] mail a message
      # @see https://bitbucket.org/mailchimp/mandrill-api-ruby/src/d0950a6f9c4fac1dd2d5198a4f72c12c626ab149/lib/mandrill/api.rb?at=master#cl-738
      # @see https://bitbucket.org/mailchimp/mandrill-api-ruby/src/d0950a6f9c4fac1dd2d5198a4f72c12c626ab149/lib/mandrill.rb?at=master#cl-32
      def deliver!(mail)
        parameters = settings.dup
        parameters.delete(:return_response)
        message = MultiMail::Message::Mandrill.new(mail).to_mandrill_hash.merge(parameters)

        response = Faraday.post('https://mandrillapp.com/api/1.0/messages/send.json', JSON.dump({
          :key     => api_key,
          :message => message,
          :async   => async,
          :ip_pool => ip_pool,
          :send_at => send_at,
        }))

        body = JSON.load(response.body)

        unless response.status == 200
          if body['status'] == 'error' && body['name'] == 'Invalid_Key'
            raise InvalidAPIKey
          else
            raise body['message']
          end
        end

        if settings[:return_response]
          body
        else
          self
        end
      end
    end
  end
end
