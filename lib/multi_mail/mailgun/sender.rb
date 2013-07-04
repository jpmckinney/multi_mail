require 'multi_mail/mailgun/message'

module MultiMail
  module Sender
    # Mailgun's outgoing mail sender.
    class Mailgun
      include MultiMail::Sender::Base

      requires :api_key, :domain

      attr_reader :api_key, :domain

      # Initializes a Mailgun outgoing email sender.
      #
      # @param [Hash] options required and optional arguments
      # @option options [String] :api_key a Mailgun API key
      def initialize(options = {})
        super
        @api_key = settings.delete(:api_key)
        @domain  = settings.delete(:domain)
      end

      # Returns the additional parameters for the API call.
      #
      # @return [Hash] the additional parameters for the API call
      def parameters
        parameters = settings.dup
        parameters.delete(:return_response)

        [:opens, :clicks].each do |sym|
          if tracking.key?(sym)
            parameter = :"o:tracking-#{sym}"
            case tracking[sym]
            when 'yes', 'no', 'htmlonly'
              parameters[parameter] = tracking[sym]
            when true
              parameters[parameter] = 'yes'
            when false
              parameters[parameter] = 'no'
            end # ignore nil
          end
        end

        parameters
      end

      # Delivers a message via the Mailgun API.
      #
      # @param [Mail::Message] mail a message
      def deliver!(mail)
        message = MultiMail::Message::Mailgun.new(mail).to_mailgun_hash.merge(parameters)

        connection = Faraday.new do |conn|
          conn.basic_auth 'api', api_key
          conn.request :multipart
          conn.request :url_encoded
          conn.adapter Faraday.default_adapter
        end

        response = connection.post("https://api.mailgun.net/v2/#{domain}/messages", message)

        case response.status
        when 401
          raise InvalidAPIKey, response.body
        when 400
          body = JSON.load(response.body)
          case body['message']
          when "'from' parameter is missing"
            raise MissingSender, body['message']
          when "'to' parameter is missing"
            raise MissingRecipients, body['message']
          when "Need at least one of 'text' or 'html' parameters specified"
            raise MissingBody, body['message']
          else
            raise InvalidMessage, body['message']
          end
        when 200
          body = JSON.load(response.body)
        else
          raise response.body
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
