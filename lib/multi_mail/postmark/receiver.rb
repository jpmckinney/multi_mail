module MultiMail
	module Receiver
		#postmarks incoming email Receiver
		class Postmark < MultiMail::Service
			include MultiMail::Receiver::Base

			#Initializes a Postmark incoming email receiver
			#
			#

			def initialize(options = {})
				super
			end

			#returns wether the Received-SPF field within the header is 
			#pass or fail
			def valid?(params)
				params['Headers'][4]['Value'].include?('Pass')
			end

			def transform(params)
				email = Mail.new do

					#these fields are not held in the header
					from params['From']
					to params['To']
					cc params['Cc']
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
			end

			def spam?(message)
				message['X-Spam-Status'].to_s == "Yes"
			end
		end
	end
end
