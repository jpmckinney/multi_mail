module MultiMail
  module Sender
    class Mandrill < MultiMail::Service
      include MultiMail::Sender::Base

      #requires :

      # @param [Hash] values required and optional arguments
      def initialize(options = {})
        super
        self.settings = options
        # @todo Set API keys, etc.
      end

      # @param [Mail::Message] mail a message
      def deliver!(mail)
        smtp_from, smtp_to, tmp_message = check_delivery_params(mail)
        m = ::Mandrill::API.new(settings[:api_key])
        message = {
          :subject => mail[:subject].to_s,
          :from_name => smtp_from,    #change this
          :text => tmp_message,
          :to =>[
            {
              :email => smtp_to[0],     #had to access first element since smtp_to is array, will fix.
              :name => mail[:to],       #change this
            }
          ],
          :html => "placeholder",
          :from_email => smtp_from
        }
        sending = m.messages.send message
        # @todo Send API requests
      end
    end
  end
end

