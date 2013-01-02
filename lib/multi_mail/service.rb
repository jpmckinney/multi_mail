module MultiMail
  # Interacts with email APIs to send or receive email.
  #
  # @see http://rdoc.info/gems/fog/Fog/Service
  class Service
    # Initializers an email API service.
    #
    # @param [Hash] options optional arguments
    def initialize(options = {})
      self.class.validate_options(options)
    end

    class << self
      # Appends the given arguments to the list of required arguments.
      #
      # @param args one or more required arguments
      # @see Fog::Service::requires
      def requires(*args)
        requirements.concat(args)
      end

      # Returns the list of required arguments.
      #
      # @return [Array] a list of required arguments
      # @see Fog::Service::requirements
      def requirements
        @requirements ||= []
      end

      # Appends the given arguments to the list of optional arguments.
      #
      # @param args one or more optional arguments
      # @see Fog::Service::recognizes
      def recognizes(*args)
        recognized.concat(args)
      end

      # Returns the list of optional arguments.
      #
      # @return [Array] a list of optional arguments
      # @see Fog::Service::recognized
      def recognized
        @recognized ||= []
      end

      # Ensures that required arguments are present and that optional arguments
      # are recognized.
      #
      # @param [Hash] options arguments
      # @raise [ArgumentError] if it can't find a required argument or can't
      #   recognize an optional argument
      # @see Fog::Service::validate_options
      def validate_options(options)
        keys = []
        for key, value in options
          unless value.nil?
            keys << key
          end
        end
        missing = requirements - keys
        unless missing.empty?
          raise ArgumentError, "Missing required arguments: #{missing.join(', ')}"
        end

        unless recognizes.empty?
          unrecognized = options.keys - requirements - recognized
          unless unrecognized.empty?
            raise ArgumentError, "Unrecognized arguments: #{unrecognized.join(', ')}"
          end
        end
      end
    end
  end
end
