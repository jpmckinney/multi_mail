module MultiMail
  # Endpoint for initializing different incoming email receivers.
  #
  # @see http://rdoc.info/gems/fog/Fog/Storage
  module Sender
    # Initializes an outgoing email receiver.
    #
    # @example
    #   require 'multi_mail'
    #   service = MultiMail::Sender.new({
    #     :provider => 'mailgun',
    #     :mailgun_api_key => 'key-xxxxxxxxxxxxxxxxxxxxxxx-x-xxxxxx',
    #   })
    #
    # @param [Hash] attributes required arguments
    # @option attributes [String,Symbol] :provider a provider
    # @return [MultiMail::Service] an incoming email receiver
    # @raise [ArgumentError] if the provider does not exist
    # @see Fog::Storage::new
    def self.new(attributes)
      attributes = attributes.dup # prevent delete from having side effects
      case provider = attributes.delete(:provider).to_s.downcase.to_sym
      when :cloudmailin
        require 'multi_mail/cloudmailin/sender'
        MultiMail::Sender::Cloudmailin.new(attributes)
      when :mailgun
        require 'multi_mail/mailgun/sender'
        MultiMail::Sender::Mailgun.new(attributes)
      when :mandrill
        require 'multi_mail/mandrill/sender'
        require 'mandrill'
        MultiMail::Sender::Mandrill.new(attributes)
      when :postmark
        require 'multi_mail/postmark/sender'
        require 'postmark'
        MultiMail::Sender::Postmark.new(attributes)
      when :sendgrid
        require 'multi_mail/sendgrid/sender'
        MultiMail::Sender::SendGrid.new(attributes)
      when :simple
        require 'multi_mail/simple/sender'
        MultiMail::Sender::Simple.new(attributes)
      else
        raise ArgumentError.new("#{provider} is not a recognized provider")
      end
    end
  end
end
