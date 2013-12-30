module MultiMail
  module Sender
    # Abstract class for outgoing email senders.
    module Base
      def self.included(subclass)
        subclass.class_eval do
          extend MultiMail::Service
        end
      end

      attr_reader :tracking
      attr_accessor :settings

      # Initializes an outgoing email sender.
      #
      # @param [Hash] options required and optional arguments
      def initialize(options = {})
        @settings = {}

        options.keys.each do |key| # based on Hash#symbolize_keys! from Rails
          settings[(key.to_sym rescue key) || key] = options[key]
        end

        self.class.validate_options(settings, false)

        @tracking = settings.delete(:track) || {}
      end
    end
  end
end
