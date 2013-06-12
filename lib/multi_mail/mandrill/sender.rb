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

        ## extract recipients
        to = []
        smtp_to.each_with_index do |recipient , i|
          to << {
            :email => recipient,
            :name => mail[:to].display_names[i]
          }
        end

        ## extract text and html parts
        if mail.multipart?
          text = mail.body.preamble 
#          text << mail.body.epilogue if mail.body.epilogue
        else
          text = mail.body.decoded
        end

        html = mail.parts.find do |part|
          part.content_type == 'text/html; charset=UTF-8'
        end
        html = html.body if html

        message = {
          :subject => mail[:subject].to_s,
          :from_name => mail[:from].display_names.first,    #change this
          :text => text,
          :to => to,
          :html => html,
          :from_email => smtp_from
        }



        response = m.messages.send message

        if settings[:return_response]
          response
        else
          self
        end
        # @todo Send API requests
      end
    end
  end
end

