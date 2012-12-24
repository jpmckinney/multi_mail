# None of the following gems or projects receive incoming emails:
#
# * https://github.com/hardikshah/mailgun.rb
# * https://github.com/HashNuke/mailgun
# * https://github.com/rschmukler/holster
# * https://github.com/jhm15217/mailgun-email-receiving
# * https://github.com/mguterl/mailgun_webhooks
# * https://github.com/perfectline/mailgun-rails
# * https://github.com/tylerhunt/pew_pew
module MultiMail
  class Mailgun < MultiMail::Service
    requires :mailgun_api_key

    # @param [Hash] options required and optional arguments
    # @option opts [String] :mailgun_api_key a Mailgun API key
    def initialize(options = {})
      super
      @mailgun_api_key = options[:mailgun_api_key]
    end

    # @param [Hash] params the content of Mailgun's webhook
    # @return [Boolean] whether the request originates from Mailgun
    # @raises [KeyError] if the request is missing parameters
    # @see http://documentation.mailgun.net/user_manual.html#securing-webhooks
    def valid?(params)
      params.fetch('signature') == OpenSSL::HMAC.hexdigest(
        OpenSSL::Digest::Digest.new('sha256'), @mailgun_api_key,
        '%s%s' % [params.fetch('timestamp'), params.fetch('token')])
    end

    # @param [Hash] params the content of Mailgun's webhook
    # @return [Mail::Message] a message
    # @note Mailgun sends the message headers both individually and in the
    #   `message-headers` parameter. Only `message-headers` is documented.
    def transform(params)
      headers = Multimap.new
      JSON.parse(params['message-headers']).each do |key,value|
        headers[key] = value
      end

      message = Mail.new do
        headers headers

        # The following are redundant with `message-headers`:
        #from    params['from']
        #sender  params['sender']
        #to      params['recipient']
        #subject params['subject']

        text_part do
          body params['body-plain']
        end

        html_part do
          content_type 'text/html; charset=UTF-8'
          body params['body-html']
        end
      end

      # Extra Mailgun parameters.
      [ 'stripped-text',
        'stripped-signature',
        'stripped-html',
        'attachment-count',
        'attachment-x',
        'content-id-map',
      ].each do |key|
        message[key] = params[key]
      end

      message
    end

    # @param [Mail::Message] message a message
    # @return [Boolean] whether the message is spam
    # @see http://documentation.mailgun.net/user_manual.html#spam-filter
    # @note You must enable spam filtering for each domain in Mailgun's [Control
    #   Panel](https://mailgun.net/cp/domains).
    # @note We may also inspect `X-Mailgun-SScore` and `X-Mailgun-Spf`, whose
    #   possible values are "Pass", "Neutral", "Fail" and "SoftFail".
    def spam?(message)
      message['X-Mailgun-Sflag'].value == 'Yes'
    end
  end
end
