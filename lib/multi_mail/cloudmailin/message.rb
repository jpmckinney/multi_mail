module MultiMail
  module Message
    class Cloudmailin < MultiMail::Message::Base
      attr_accessor :reply_plain, :spf_result
    end
  end
end
