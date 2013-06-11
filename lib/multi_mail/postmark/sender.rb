module MultiMail
  module Sender
    #Postmarks outgoing mail sender
    class Postmark < MultiMail::Service
      include MultiMail::Sender::Base
      requires :api_key
      
      def initialize(options = {})
        super
        @postmark_api_key = options[:api_key]
      end

      def deliver!(mail)
        mail.delivery_method Mail::Postmark, :api_key => @postmark_api_key   
        mail.deliver 
      end
    end
  end
end