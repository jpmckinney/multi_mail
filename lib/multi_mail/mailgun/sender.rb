module MultiMail
  module Sender
    class Mailgun < MultiMail::Service
      include MultiMail::Sender::Base

      requires :api_key, :domain_name

      # @param [Hash] values required and optional arguments
      def initialize(values)
        super
        @api_key = values.delete(:api_key)
        @domain_name = values.delete(:domain_name)
        self.settings = values
        # @todo Set API keys, etc.
      end

      # @param [Mail::Message] mail a message
      def deliver!(mail)
        smtp_from, smtp_to, message = check_delivery_params(mail)
        # @todo Send API requests

        # extract html
        html = mail.parts.find do |part|
          part.content_type == 'text/html; charset=UTF-8'
        end
        html = html.body if html



        message = Multimap[
          :from => smtp_from,
          :to => smtp_to,
          :subject => mail[:subject].to_s,
          :text => mail.body.decoded,
          :html => html,
          "o:tag" => mail[:tags]
        ]
        message[:cc] = mail.cc if mail.cc
        message[:bcc] = mail.bcc if mail.bcc

        #extract attachments
        mail.attachments.each do |a|
          filename, extension = a.filename.split('.')
          file = Tempfile.new([filename, extension])
          file.write(a.decoded)
          file.close
          if extension == 'jpg' || extension == 'tiff'
            message[:inline] = File.new(file.path)
          else
            message[:attachment] = File.new(file.path)
          end
        end
        
        message.merge!(settings[:message_options]) if settings[:message_options]

        RestClient.post(
          "https://api:#{@api_key}@api.mailgun.net/v2/#{@domain_name}/messages",
          message
        )

      end
    end
  end
end
