require 'mail/check_delivery_params'

module MultiMail
  module Sender
    # Abstract class for outgoing email services.
    #
    # The `deliver!` instance method must be implemented in sub-classes.
    module Base
      def self.included(subclass)
        subclass.class_eval do
          include Mail::CheckDeliveryParams
        end
      end

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
