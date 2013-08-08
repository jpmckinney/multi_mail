require 'multi_mail/mandrill/message'

module MultiMail
  module Sender
    # Mandrill's outgoing mail sender.
    class Mandrill
      include MultiMail::Sender::Base

      requires :api_key

      attr_reader :api_key, :async, :ip_pool, :send_at

      # Initializes a Mandrill outgoing email sender.
      #
      # @param [Hash] options required and optional arguments
      # @option options [String] :api_key a Mandrill API key
      # @option options [Boolean] :async whether to enable a background sending
      #   mode optimized for bulk sending
      # @option options [String] :ip_pool the name of the dedicated IP pool that
      #   should be used to send the message
      # @option options [Time,String] :send_at when this message should be sent
      # @see https://mandrillapp.com/api/docs/index.ruby.html
      # @see https://mandrillapp.com/api/docs/messages.JSON.html#method-send
      def initialize(options = {})
        super
        @api_key = settings.delete(:api_key)
        @async   = settings.delete(:async) || false
        @ip_pool = settings.delete(:ip_pool)
        @send_at = settings.delete(:send_at)
        unless @send_at.nil? or String === @send_at
          @send_at = @send_at.utc.strftime('%Y-%m-%d %T')
        end
      end

      # Returns the additional parameters for the API call.
      #
      # @return [Hash] the additional parameters for the API call
      def parameters
        parameters = settings.dup
        parameters.delete(:return_response)

        [:opens, :clicks].each do |sym|
          if tracking.key?(sym)
            parameter = :"track_#{sym}"
            case tracking[sym]
            when true, false, nil
              parameters[parameter] = tracking[sym]
            when 'yes'
              parameters[parameter] = true
            when 'no'
              parameters[parameter] = false
            end # ignore "htmlonly"
          end
        end

        parameters
      end

      # Delivers a message via the Mandrill API.
      #
      # @param [Mail::Message] mail a message
      # @see https://bitbucket.org/mailchimp/mandrill-api-ruby/src/d0950a6f9c4fac1dd2d5198a4f72c12c626ab149/lib/mandrill/api.rb?at=master#cl-738
      # @see https://bitbucket.org/mailchimp/mandrill-api-ruby/src/d0950a6f9c4fac1dd2d5198a4f72c12c626ab149/lib/mandrill.rb?at=master#cl-32
      def deliver!(mail)
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
          if body['status'] == 'error'
            case body['name']
            when 'Invalid_Key'
              raise InvalidAPIKey, body['message']
            else
              raise body['message']
            end
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
