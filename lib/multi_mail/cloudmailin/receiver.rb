module MultiMail
  module Receiver
    # Cloudmailin's incoming email receiver.
    #
    # Cloudmailin recommends using basic authentication over HTTPS to ensure
    # that a request originates from Cloudmailin.
    #
    # @see http://docs.cloudmailin.com/receiving_email/securing_your_email_url_target/
    class Cloudmailin
      include MultiMail::Receiver::Base

      recognizes :http_post_format, :attachment_store

      # Initializes a Cloudmailin incoming email receiver.
      #
      # @param [Hash] options required and optional arguments
      # @option options [String] :http_post_format "multipart", "json" or "raw"
      # @option options [Boolean] :attachment_store whether attachments have
      #   been sent to an attachment store
      def initialize(options = {})
        super
        @http_post_format = options[:http_post_format]
        @attachment_store = options[:attachment_store]
      end

      # @param [Hash] params the content of Cloudmailin's webhook
      # @return [Array<MultiMail::Message::Cloudmailin>] messages
      # @see http://docs.cloudmailin.com/http_post_formats/multipart/
      # @see http://docs.cloudmailin.com/http_post_formats/json/
      # @see http://docs.cloudmailin.com/http_post_formats/raw/
      def transform(params)
        case @http_post_format
        when 'raw', '', nil
          message = self.class.condense(MultiMail::Message::Cloudmailin.new(Mail.new(params['message'])))

          # Extra Cloudmailin parameters.
          message.spf_result = params['envelope']['spf']['result']

          if @attachment_store
            params['attachments'].each do |_,attachment|
              message.add_file(:filename => attachment['file_name'], :content => Faraday.get(attachment['url']).body)
            end
          end

          # Discard rest of `envelope`: `from`, `to`, `recipients`,
          # `helo_domain` and `remote_ip`.
          [message]
        when 'multipart', 'json'
          # Mail changes `self`.
          headers = self.class.multimap(params['headers'])
          http_post_format = @http_post_format
          attachment_store = @attachment_store
          this = self

          message = MultiMail::Message::Cloudmailin.new do
            headers headers

            text_part do
              body params['plain']
            end

            if params.key?('html')
              html_part do
                content_type 'text/html; charset=UTF-8'
                body params['html']
              end
            end

            if params.key?('attachments')
              # Using something like lazy.rb will not prevent the HTTP request,
              # because the Mail gem must be able to call #valid_encoding? on
              # the attachment body (in Ruby 1.9).
              if http_post_format == 'json'
                params['attachments'].each do |attachment|
                  if attachment_store
                    add_file(:filename => attachment['file_name'], :content => Faraday.get(attachment['url']).body)
                  else
                    add_file(:filename => attachment['file_name'], :content => Base64.decode64(attachment['content']))
                  end
                end
              else
                params['attachments'].each do |_,attachment|
                  if attachment_store
                    add_file(:filename => attachment['file_name'], :content => Faraday.get(attachment['url']).body)
                  else
                    add_file(this.class.add_file_arguments(attachment))
                  end
                end
              end
            end
          end

          # Extra Cloudmailin parameters. The multipart format uses CRLF whereas
          # the JSON format uses LF. Normalize to LF.
          message.reply_plain = params['reply_plain'].gsub("\r\n", "\n")
          message.spf_result  = params['envelope']['spf']['result']

          [message]
        else
          raise ArgumentError, "Can't handle Cloudmailin #{@http_post_format} HTTP POST format"
        end
      end

      # @param [Mail::Message] message a message
      # @return [Boolean] whether the message is spam
      def spam?(message)
        message.spf_result == 'fail'
      end
    end
  end
end
