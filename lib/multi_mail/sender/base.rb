module MultiMail
  module Sender
    # Abstract class for outgoing email senders.
    module Base
      def self.included(subclass)
        subclass.class_eval do
          extend MultiMail::Service
        end
      end

      attr_reader :settings, :tracking

      # Initializes an outgoing email sender.
      #
      # @param [Hash] options required and optional arguments
      def initialize(options = {})
        @settings = {}
        @tracking = {}

        options.keys.each do |key| # based on Hash#symbolize_keys! from Rails
          settings[(key.to_sym rescue key) || key] = options[key]
        end

        self.class.validate_options(settings, false)

        [:opens, :clicks].each do |sym|
          if settings.key?(:"track_#{sym}") || settings.key?(:"o:tracking-#{sym}")
            tracking[sym] = settings.delete(:"track_#{sym}") || settings.delete(:"o:tracking-#{sym}")
          end
        end
      end
    end
  end
end
