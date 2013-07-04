module MultiMail
  module Sender
    # Abstract class for outgoing email senders.
    module Base
      def self.included(subclass)
        subclass.class_eval do
          extend MultiMail::Service
        end
      end

      attr_reader :settings

      # Initializes an outgoing email sender.
      #
      # @param [Hash] options required and optional arguments
      def initialize(options = {})
        @settings = {}

        # Based on Hash#symbolize_keys! from Rails.
        options.keys.each do |key|
          settings[(key.to_sym rescue key) || key] = options[key]
        end

        self.class.validate_options(options, false)
      end
    end
  end
end
