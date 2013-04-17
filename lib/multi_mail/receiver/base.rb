module MultiMail
  module Receiver
    # Abstract class for incoming email receivers.
    #
    # The `transform` instance method must be implemented in sub-classes. The
    # `valid?` and `spam?` instance methods may be implemented in sub-classes.
    module Base
      def self.included(subclass)
        subclass.class_eval do
          extend MultiMail::Receiver::Base::ClassMethods
        end
      end

      # Ensures a request is authentic, parses it into a params hash, and
      # transforms it into a list of messages.
      #
      # @param [String,Hash] raw raw POST data or a params hash
      # @return [Array<Mail::Message>] messages
      # @raise [ForgedRequest] if the request is not authentic
      def process(raw)
        params = self.class.parse(raw)
        if valid?(params)
          transform(params)
        else
          raise ForgedRequest
        end
      end

      # Returns whether a request is authentic.
      #
      # @param [Hash] params the content of the provider's webhook
      # @return [Boolean] whether the request is authentic
      def valid?(params)
        true
      end

      # Transforms the content of a provider's webhook into a list of messages.
      #
      # @param [Hash] params the content of the provider's webhook
      # @return [Array<Mail::Message>] messages
      def transform(params)
        raise NotImplementedError
      end

      # Returns whether a message is spam.
      #
      # @param [Mail::Message] message a message
      # @return [Boolean] whether the message is spam
      def spam?(message)
        false
      end

      module ClassMethods
        # Parses raw POST data into a params hash.
        #
        # @param [String,Hash] raw raw POST data or a params hash
        # @raise [ArgumentError] if the argument is not a string or a hash
        def parse(raw)
          case raw
          when String
            begin
              JSON.parse(raw)
            rescue JSON::ParserError
              params = CGI.parse(raw)

              # Flatten the parameters.
              params.each do |key,value|
                if Array === value && value.size == 1
                  params[key] = value.first
                end
              end

              params
            end
          when Array
            params = {}

            # Collect the values for each key.
            map = Multimap.new
            raw.each do |key,value|
              map[key] = value
            end

            # Flatten the parameters.
            map.each do |key,value|
              if Array === value && value.size == 1
                params[key] = value.first
              else
                params[key] = value
              end
            end

            params
          when Hash
            raw
          else
            raise ArgumentError, "Can't handle #{raw.class.name} input"
          end
        end

        # Condenses a message's HTML parts to a single HTML part.
        #
        # @example
        #   flat = self.class.condense(message.dup)
        #
        # @param [Mail::Message] message a message with zero or more HTML parts
        # @return [Mail::Message] the message with a single HTML part
        def condense(message)
          if message.multipart? && message.parts.any?(&:multipart?)
            # Get the message parts as a flat array.
            result = flatten(Mail.new, message.parts.dup)

            # Rebuild the message's parts.
            message.parts.clear

            # Merge non-attachments with the same content type.
            (result.parts - result.attachments).group_by(&:content_type).each do |content_type,group|
              body = group.map{|part| part.body.decoded}.join

              # Make content types match across all APIs.
              if content_type == 'text/plain; charset=us-ascii'
                # `text/plain; charset=us-ascii` is the default content type.
                content_type = 'text/plain'
              elsif content_type == 'text/html; charset=us-ascii'
                content_type = 'text/html; charset=UTF-8'
                body = body.encode('UTF-8') if body.respond_to?(:encode)
              end

              message.parts << Mail::Part.new({
                :content_type => content_type,
                :body => body,
              })
            end

            # Add attachments last.
            result.attachments.each do |part|
              message.parts << part
            end
          end

          message
        end

        # Flattens a hierarchy of message parts.
        #
        # @example
        #   flat = self.class.flatten(Mail.new, parts.dup)
        #
        # @param [Mail::Message] message a message
        # @param [Mail::PartsList] parts parts to add to the message
        # @return [Mail::Message] the message with all the parts
        def flatten(message, parts)
          parts.each do |part|
            if part.multipart?
              flatten(message, part.parts)
            else
              message.parts << part
            end
          end
          message
        end
      end
    end
  end
end
