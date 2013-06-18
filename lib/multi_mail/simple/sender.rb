module MultiMail
  module Sender
    class Simple < MultiMail::Service
      include MultiMail::Sender::Base

      requires 

      def initialize(values)
        self.settings = values
      end

      def deliver!(mail)
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

