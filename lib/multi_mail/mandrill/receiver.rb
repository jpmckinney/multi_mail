module MultiMail
  module Receiver
    class Mandrill < MultiMail::Service
      include MultiMail::Receiver::Base

      requires :mandrill_api_key

      # Initializes a Mandrill incoming email receiver.
      #
      # @param [Hash] options required and optional arguments
      # @option opts [String] :mandrill_api_key a Mandrill API key
      def initialize(options = {})
        super
        @mandrill_api_key = options[:mandrill_api_key]
      end

      # Returns whether a request is an inbound event.
      #
      # @param [Hash] params the content of Mandrill's webhook
      # @return [Boolean] whether the request is an inbound event
      def valid?(params)
        JSON.parse(params['mandrill_events']).all? do |event|
          event.fetch('event') == 'inbound'
        end
      end

      # Transforms the content of Mandrill's webhook into a list of messages.
      #
      # @param [Hash] params the content of Mandrill's webhook
      # @return [Array<Mail::Message>] messages
      # @todo parse attachments properly
      def transform(params)
        JSON.parse(params['mandrill_events']).map do |event|
          message = Mail.new do
            headers event['msg']['headers'].reject{|k,_| k=='Received'} # @todo

            # The following are redundant with `message-headers`:
            #
            # address = Mail::Address.new event['msg']['from_email']
            # address.display_name = event['msg']['from_name']
            #
            # from    address.format
            # to      event['msg']['to'].flatten.compact
            # subject event['msg']['subject']

            text_part do
              body event['msg']['text']
            end

            html_part do
              content_type 'text/html; charset=UTF-8' # unsure about charset
              body event['msg']['html']
            end
          end

          # Extra Mandrill parameters. Discard `raw_msg`.
          [ 'email',
            'tags',
            'sender',
          ].each do |key|
            if !event['msg'][key].nil? && !event['msg'][key].empty?
              message[key] = event['msg'][key]
            end
          end

          message
        end
      end

      # Returns whether a message is spam.
      #
      # @param [Mail::Message] message a message
      # @return [Boolean] whether the message is spam
      def spam?(message)
        false
      end
    end
  end
end
