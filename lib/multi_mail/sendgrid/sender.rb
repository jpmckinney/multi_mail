module MultiMail
  module Sender
    class SendGrid < MultiMail::Service
      include MultiMail::Sender::Base

      requires :user_name, :api_key

      # @param [Hash] values required and optional arguments
      def initialize(values)
        super
        self.settings = values
        @user_name = values[:user_name]
        @api_key = values[:api_key]
      end

      # @param [Mail::Message] mail a message
      def deliver!(mail)
        smtp_from, smtp_to, message = check_delivery_params(mail)
        
        ## extract html
        html = mail.parts.find do |part|
          part.content_type == 'text/html; charset=UTF-8'
        end
        html = html.body if html

        ##extract attachments
        attachments = mail.attachments.map do |a|
          {
            :name => a.filename,
            :type => a.mime_type,
            :content => Base64.encode64(a.decoded)
          }
        end

        message = {
          :to => smtp_to,
          :toname => mail[:to].display_names,
          "x-smptpapi" => nil,                    #nil for now
          :subject => mail[:subject].to_s,
          :text => mail.body.decoded,
          :html => html,
          :from => smtp_from,
          :bcc => mail.bcc,
          :fromname => mail[:from].display_names.first,
          :files => attachments,
        }
        params = {:api_user => @user_name, :api_key => @api_key}.merge(message)

        response = RestClient.post(
          "https://sendgrid.com/api/mail.send.json",
          params,
          :content_type => :json
          ) {|response,request|
          response
        }

        if settings[:return_response]
          response
        else
          self
        end
        # @todo Send API requests
      end
    end
  end
end
