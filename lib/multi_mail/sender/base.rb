module MultiMail
  module Sender
    # Abstract class for outgoing email services.
    #
    # The `deliver!` instance method must be implemented in sub-classes.
    module Base
      attr_accessor :settings

      # Delivers a message.
      #
      # @param [Mail::Message] mail a message
      def deliver!(mail)
        raise NotImplementedError
      end
    end
  end
end
