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
        mail.deliver 
      end
    end
  end
end