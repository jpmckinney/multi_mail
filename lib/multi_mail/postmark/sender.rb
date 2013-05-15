module MultiMail
  module Sender
    class Postmark < MultiMail::Service
      include MultiMail::Sender::Base

      #requires :

      # @param [Hash] options required and optional arguments
      def initialize(options = {})
        super
      end
    end
  end
end
