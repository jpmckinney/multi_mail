module MultiMail
	module Sender
		class SendGrid < MultiMail::Service
			include MultiMail::Sender::base

			def initialize(options = {})
				super
			end
		end
	end
end
