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

	#		def valid?(params)
#			end

			def transform(params)
				email = Mail.new do
					#this is where things are getting messed up
					headers Hash[params['Headers']]
					body params['TextBody']


					html_part do
            content_type 'text/html; charset=UTF-8'
            body params['HtmlBody']
          end if params['HtmlBody']

          params['Attachments'].each do |attachment|
          	add_file(:filename => attachment['Name'], :content => attachment['Content'])
          end
				end
			end

			def spam?(message)
				message['headers']['X-Spam-Status'] == "Yes"
			end
		end
	end
end
