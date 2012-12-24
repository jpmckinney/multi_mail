require 'cgi'
require 'json'
require 'openssl'

require 'mail'
require 'multimap'

# @see https://github.com/fog/fog/blob/master/lib/fog/core.rb
require 'multi_mail/error'
require 'multi_mail/service'

# @see http://rdoc.info/gems/fog/Fog/Storage
module MultiMail
  # @example
  #   require 'multi_mail'
  #   service = MultiMail.new({
  #     :provider => 'mailgun',
  #     :mailgun_api_key => 'key-xxxxxxxxxxxxxxxxxxxxxxx-x-xxxxxx',
  #   })
  #
  # @param [Hash] attributes required arguments
  # @option opts [String,Symbol] :provider a provider
  # @raises [ArgumentError] if the provider does not exist
  # @see Fog::Storage::new
  def self.new(attributes)
    attributes = attributes.dup # prevent delete from having side effects
    case provider = attributes.delete(:provider).to_s.downcase.to_sym
    when :mailgun
      require 'multi_mail/services/mailgun'
      MultiMail::Mailgun.new(attributes)
    when :mandrill
      require 'multi_mail/services/mandrill'
      MultiMail::Mandrill.new(attributes)
    else
      raise ArgumentError.new("#{provider} is not a recognized provider")
    end
  end
end
