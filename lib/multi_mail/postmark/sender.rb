module MultiMail
  module Sender
    #Postmarks outgoing mail sender
    class Postmark < MultiMail::Service
      include MultiMail::Sender::Base
      requires :api_key
      
      def initialize(options = {})
        super
        self.settings = options
      end

      def deliver!(mail)
        mail.delivery_method Mail::Postmark, self.settings
        response = mail.deliver
        
        if settings[:return_response]
          response
        else
          self  
        end
      end
    end
  end
end