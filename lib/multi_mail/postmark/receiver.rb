module MultiMail
  module Receiver
    # Postmark's incoming email receiver.
    class Postmark < MultiMail::Service
      include MultiMail::Receiver::Base

      def transform(params)
        headers = Multimap.new
        params['Headers'].each do |header|
          headers[header['Name']] = header['Value']
        end

        # Due to scoping issues, we can't call `address` within `Mail.new`.
        from = transform_address(params['FromFull'])
        to   = params['ToFull'].map{|hash| transform_address(hash)}
        cc   = params['CcFull'].map{|hash| transform_address(hash)}

        message = Mail.new do
          from      from
          to        to
          cc        cc
          reply_to  params['ReplyTo']
          subject   params['Subject']
          date      params['Date']

          text_part do
            body params['TextBody']
          end

          html_part do
            content_type 'text/html; charset=UTF-8'
            body CGI.unescapeHTML(params['HtmlBody'])
          end

          headers headers

          params['Attachments'].each do |attachment|
            add_file(:filename => attachment['Name'], :content => Base64.decode64(attachment['Content']))
          end
        end

        # Extra Postmark parameters.
        %w(MailboxHash MessageID Tag).each do |key|
          message[key] = params[key]
        end

        [message]
      end

      # @param [Mail::Message] message a message
      # @return [Boolean] whether the message is spam
      # @see http://developer.postmarkapp.com/developer-inbound-parse.html#spam
      def spam?(message)
        message['X-Spam-Status'].value == 'Yes'
      end

    private

      def transform_address(hash)
        address = Mail::Address.new(hash['Email'])
        address.display_name = hash['Name']
        address.to_s
      end
    end
  end
end
