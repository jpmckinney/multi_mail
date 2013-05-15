module MultiMail
  module Receiver
    # Postmark's incoming email receiver.
    class Postmark < MultiMail::Service
      include MultiMail::Receiver::Base

      def transform(params)
        message = Mail.new do

          address = Mail::Address.new params['FromFull']['Email']
          address.display_name = params['FromFull']['Name']
          from address

          to(params['ToFull'].map do |recipient|
          	address = Mail::Address.new recipient['Email']
          	address.display_name = recipient['Name']
          	address.to_s
          end)

          cc(params['CcFull'].map do |recipient|
          	address = Mail::Address.new recipient['Email']
          	address.display_name = recipient['Name']
          	address.to_s
          end)
          
          message_id params['MessageID']
          subject params['Subject']
          date DateTime.parse(params['Date'])

          body params['TextBody']
          html_part do
            content_type 'text/html; charset=UTF-8'
            body params['HtmlBody']
          end if params['HtmlBody']

          headers = Multimap.new
          params['Headers'].each do |header|
            key = header['Name']
            value = header['Value']
            headers[key] = value
          end

          headers headers

          params['Attachments'].each do |attachment|
            add_file(:filename => attachment['Name'], :content => Base64.decode64(attachment['Content']))
          end
        end

        [message]
      end

      def spam?(message)
        message['X-Spam-Status'].to_s == "Yes"
      end
    end
  end
end
