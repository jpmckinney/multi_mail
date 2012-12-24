module MultiMail
  # Abstract class for incoming email services.
  #
  # The `transform` instance method must be implemented in sub-classes. The
  # `valid?` and `spam?` instance methods may be implemented in sub-classes.
  #
  # @see http://rdoc.info/gems/fog/Fog/Service
  class Service
    class ForgedRequest < MultiMail::Error; end

    # @param [Hash] options optional arguments
    def initialize(options = {})
      self.class.validate_options(options)
    end

    # @param [String,Hash] raw raw POST data or a params hash
    # @return [Mail::Message] a message
    # @raises [ForgedRequest] if the request is not authentic
    def process(raw)
      params = self.class.parse raw
      if valid? params
        transform params
      else
        raise ForgedRequest
      end
    end

    # @param [Hash] params the content of the provider's webhook
    # @return [Boolean] whether the request is authentic
    def valid?(params)
      true
    end

    # @param [Hash] params the content of the provider's webhook
    # @return [Mail::Message] a message
    def transform(params)
      raise NotImplementedError
    end

    # @param [Mail::Message] message a message
    # @return [Boolean] whether the message is spam
    def spam?(message)
      false
    end

    class << self
      # @param [String,Hash] raw raw POST data or a params hash
      def parse(raw)
        case raw
        when String
          params = CGI.parse raw
          params.each do |key,value|
            if Array === value && value.size == 1
              params[key] = value.first
            end
          end
          params
        when Hash
          raw
        else
          raise ArgumentError, "Can't handle #{raw.class.name} webhook content"
        end
      end

      # Appends the given arguments to the list of required arguments.
      #
      # @param args one or more required arguments
      # @see Fog::Service::requires
      def requires(*args)
        requirements.concat(args)
      end

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

      # @return [Array] a list of optional arguments
      # @see Fog::Service::recognized
      def recognized
        @recognized ||= []
      end

      # @param [Hash] options arguments
      # @raises [ArgumentError] if can't find required arguments or can't
      #   recognize optional arguments
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
