require 'cgi'
require 'json'
require 'openssl'

require 'mail'
require 'multimap'

module MultiMail
  # @see http://rdoc.info/gems/fog/Fog/Errors
  class Error < StandardError; end
  class ForgedRequest < MultiMail::Error; end

  autoload :Service, 'multi_mail/service'
  autoload :Receiver, 'multi_mail/receiver'
  #autoload :Sender, 'multi_mail/sender'
end
