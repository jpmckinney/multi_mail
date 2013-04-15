module MultiMail
  # Endpoint for initializing different outgoing email senders.
  #
  # @see http://rdoc.info/gems/fog/Fog/Storage
  module Sender
    # Initializers an outgoing email sender.
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
    # @return [MultiMail::Service] an outgoing email sender
    # @raise [ArgumentError] if the provider does not exist
    # @see Fog::Storage::new
    def self.new(attributes)
      attributes = attributes.dup # prevent delete from having side effects
      case provider = attributes.delete(:provider).to_s.downcase.to_sym
      when :mailgun
        require 'multi_mail/mailgun/sender'
        MultiMail::Sender::Mailgun.new(attributes)
      when :mandrill
        require 'multi_mail/mandrill/sender'
        MultiMail::Sender::Mandrill.new(attributes)
      when :postmark
        require 'multi_mail/postmark/sender'
        MultiMail::Sender::Postmark.new(attributes)
      when :sendgrid
        require 'multi_mail/sendgrid/sender'
        MultiMail::Sender::SendGrid.new(attributes)
      when :simple
        require 'multi_mail/simple/sender'
        MultiMail::Sender::Simple.new(attributes)
      when :mock
        # for testing
        MultiMail::Sender::Mock.new(attributes)
      else
        raise ArgumentError.new("#{provider} is not a recognized provider")
      end
    end
  end
end
