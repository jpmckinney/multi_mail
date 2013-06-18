module MultiMail
  module Sender
    class Simple < MultiMail::Service
      include MultiMail::Sender::Base

      requires 

      def initialize(values)
        self.settings = values
      end

      def deliver!(mail)
        mail.deliver
      end

    end
  end
end

