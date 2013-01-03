require 'cgi'
require 'json'
require 'openssl'

require 'mail'
require 'multimap'

module MultiMail
  # @see http://rdoc.info/gems/fog/Fog/Errors
  class Error < StandardError; end
  class ForgedRequest < MultiMail::Error; end
end

require 'multi_mail/service'
require 'multi_mail/receiver'
require 'multi_mail/receiver/base'
require 'multi_mail/sender'
require 'multi_mail/sender/base'
