# MultiMail: easily switch between email APIs

[![Build Status](https://secure.travis-ci.org/opennorth/multi_mail.png)](http://travis-ci.org/opennorth/multi_mail)
[![Dependency Status](https://gemnasium.com/opennorth/multi_mail.png)](https://gemnasium.com/opennorth/multi_mail)
[![Coverage Status](https://coveralls.io/repos/opennorth/multi_mail/badge.png?branch=master)](https://coveralls.io/r/opennorth/multi_mail)
[![Code Climate](https://codeclimate.com/github/opennorth/multi_mail.png)](https://codeclimate.com/github/opennorth/multi_mail)

Many providers – including [Cloudmailin](http://www.cloudmailin.com/), [Mailgun](http://www.mailgun.com/), [Mandrill](http://mandrill.com/), [Postmark](http://postmarkapp.com/) and [SendGrid](http://sendgrid.com/) – offer APIs to send, receive, parse and forward email. MultiMail lets you easily switch between these APIs.

## Usage

    require 'multi_mail'
    
    service = MultiMail::Receiver.new(:provider => 'mandrill')
    
    message = service.process data # raw POST data or params hash

`message` is an array of [Mail::Message](https://github.com/mikel/mail) instances.

Any additional parameters provided by an API is added to the message as a header. For example, Mailgun provides `stripped-text`, which is the message body without quoted parts or signature block. You can access it with `message['stripped-text'].value`.

    service = MultiMail::Sender.new({
      :provider => :mandrill,
      :api_key => <mandrill-api-key>,
      :message_options => {
        :important => false 
      },
    })

    message = Mail.new({
      :from =>    'from@example.com',
      :to =>      ['to@example.com','to2@example.com'],
      :subject => 'this is a test',
      :body =>    'test text body',
    })

    service.deliver!(message)

check out the [Mail Gem's Documentation](https://github.com/mikel/mail#usage) for more info on creating Mail messages.  

the deliver! will return an instance of `MultiMail::Sender::Mandrill` in this case. If you wish to return the response provided by the provider (in this case Mandrill), you can initialize service using `:return_response` as such:

    service = MultiMail::Sender.new({
      :provider => :mandrill,
      :api_key => <mandrill-api-key>,
      :message_options => {
        :important => false 
      },
      :return_response => true
    })

## Supported APIs

Incoming email:

* [Cloudmailin](http://www.cloudmailin.com/): [Documentation](#cloudmailin)
* [Mailgun](http://www.mailgun.com/): [Documentation](#mailgun)
* [Mandrill](http://mandrill.com/): [Documentation](#mandrill)
* [Postmark](http://postmarkapp.com/): [Documentation](#postmark)
* [SendGrid](http://sendgrid.com/): [Documentation](#sendgrid)

Outgoing email:

* [Postmark](http://postmarkapp.com/): [Documentation](#postmark)

## Cloudmailin

    service = MultiMail::Receiver.new({
      :provider => 'cloudmailin',
    })

The default HTTP POST format is `raw`. Add a `:http_post_format` option to change the HTTP POST format, with possible values of `"multipart"`, `"json"` or `"raw"` (default). (The [original format](http://docs.cloudmailin.com/http_post_formats/original/) is deprecated.) For example:

    service = MultiMail::Receiver.new({
      :provider => 'cloudmailin',
      :http_post_format => 'raw',
    })

**Note:** [MultiMail doesn't yet support Cloudmailin's URL attachments (attachment stores).](https://github.com/opennorth/multi_mail/issues/11) Please use regular attachments (always the case if you use the `raw` format) if you are using MultiMail.

**2013-04-15:** If an email contains multiple HTML parts and you are using the `multipart` or `json` HTTP POST formats, Cloudmailin will only include the first HTML part in its `html` parameter. Use the `raw` format to avoid data loss. Cloudmailin also removes a newline from the end of each attachment.

See [Cloudmailin's documentation](http://docs.cloudmailin.com/http_post_formats/) for these additional parameters provided by the API:

* `reply_plain`
* `spf-result`

## Mailgun

### Incoming

    service = MultiMail::Receiver.new({
      :provider => 'mailgun',
      :mailgun_api_key => 'key-xxxxxxxxxxxxxxxxxxxxxxx-x-xxxxxx',
    })

If you omit the `:mailgun_api_key` option, MultiMail will not check whether a request originates from Mailgun.

If you have a route with a URL ending with "mime" and you are using the raw MIME format, add a `:http_post_format => 'raw'` option. For example:

    service = MultiMail::Receiver.new({
      :provider => 'mailgun',
      :mailgun_api_key => 'key-xxxxxxxxxxxxxxxxxxxxxxx-x-xxxxxx',
      :http_post_format => 'raw',
    })

**2013-04-15:** Mailgun's `stripped-text` and `stripped-html` parameters do not return the same parts of the message. `stripped-html` sometimes incorrectly drops non-quoted, non-signature parts of the message; `stripped-text` doesn't.

See [Mailgun's documentation](http://documentation.mailgun.net/user_manual.html#parsed-messages-parameters) for these additional parameters provided by the API:

* `stripped-text`
* `stripped-signature`
* `stripped-html`
* `content-id-map`

### Outgoing
    service = MultiMail::Sender.new({
      :provider => 'mailgun',
      :api_key => <mailgun-api-key>,
      :domain_name => <mailgun-domain-name>,
      :message_options => <optional>
      })

once you have created your mail message, call
    service.deliver!(message)

See [Mailgun's documentation](http://documentation.mailgun.com/api-sending.html) for these additional parameters provided by the api

* `o:campaign`
* `o:dkim`
* `o:deliverytime`
* `o:testmode`
* `o:tracking`
* `o:tracking-clicks`
* `o:tracking-opens`
* `h:X-My-Header`
* `v:my-var`

these can be inserted into :message_options as a hash. Ex:

    :message_options => {'o:tracking-clicks' => 'yes'}

## Mandrill

### Incoming

    service = MultiMail::Receiver.new({
      :provider => 'mandrill',
      :mandrill_webhook_key => 'xxxxxxxxxxxxxxxxxxxxxx',
      :mandrill_webhook_url => 'http://example.com/post',
    })

If you omit the `:mandrill_webhook_key` and `:mandrill_webhook_url` options, MultiMail will not check whether a request originates from Mandrill. You can get your webhook key from [Mandrill's Webhooks Settings](https://mandrillapp.com/settings/webhooks).

The default SpamAssassin score needed to flag an email as spam is `5`. Add a `:spamassassin_threshold` option to increase or decrease it. For example:

    service = MultiMail::Receiver.new({
      :provider => 'mandrill',
      :spamassassin_threshold => 4.5,
    })

**2013-04-15:** If an email contains multiple HTML parts, Mandrill will only include the first HTML part in its `html` parameter. We therefore parse its `raw_msg` parameter to set the HTML part correctly. Mandrill also adds a newline to the end of each message part.

See [Mandrill's documentation](http://help.mandrill.com/entries/22092308-What-is-the-format-of-inbound-email-webhooks-) for these additional parameters provided by the API:

* `ts`
* `email`
* `dkim-signed`
* `dkim-valid`
* `spam_report-score`
* `spf-result`

### Outgoing
    service = MultiMail::Sender.new({
      :provider => 'mandrill',
      :api_key => <mandrill-api-key>,
      })

## Postmark

### Incoming

    service = MultiMail::Receiver.new({
      :provider => 'postmark',
    })

**2013-05-15:** If an email contains multiple HTML parts, Postmark will only include the first HTML part in its `HtmlBody` parameter. You cannot avoid this loss of data. Postmark is therefore not recommended.

See [Postmark's documentation](http://developer.postmarkapp.com/developer-inbound-parse.html#mailboxhash) for these additional parameters provided by the API:

* `MailboxHash`
* `MessageID`
* `Tag`

### Outgoing

    service = MultiMail::Sender.new({
      :provider => "postmark",
      :api_key => <postmark-api-key>
      })

once you have created your mail message, call

    service.deliver!(message)



## SendGrid

### Incoming

    service = MultiMail::Receiver.new({
      :provider => 'sendgrid',
    })

The default SpamAssassin score needed to flag an email as spam is `5`. Add a `:spamassassin_threshold` option to increase or decrease it. For example:

    service = MultiMail::Receiver.new({
      :provider => 'sendgrid',
      :spamassassin_threshold => 4.5,
    })

**2013-05-17:** If an email contains multiple HTML parts, SendGrid will create a new attachment for each, with an auto-generated filename. Since we cannot robustly identify these attachments, you must inspect attachments to recover any additional HTML parts.

See [SendGrid's documentation](http://sendgrid.com/docs/API_Reference/Webhooks/parse.html) for these additional parameters provided by the API:

* `dkim`
* `SPF`
* `spam_report`
* `spam_score`

### Outgoing
    
    service = MultiMail::Sender.new({
      :provider => 'sendgrid',
      :user_name => <sendgrid_username>,
      :api_key => <sendgrid_api_key>,
      :message_options => <optional>
      })

once you have created your mail message, call
    service.deliver!(message)

see [Sendgrid's documentation](http://sendgrid.com/docs/API_Reference/Web_API/mail.html) for these additional parameters provided by the API:

* `x-smtpapi`
* `replyto`
* `date`
* `content`
* `headers`

these can be inserted into the :message_options field as a hash. Ex:

    :message_options => {"headers" => {"X-Accept-Language":"en"} } 


## Bugs? Questions?

This gem's main repository is on GitHub: [http://github.com/opennorth/multi_mail](http://github.com/opennorth/multi_mail), where your contributions, forks, bug reports, feature requests, and feedback are greatly welcomed.

## Acknowledgements

This gem is developed by [Open North](http://www.opennorth.ca/) through a partnership with the [Participatory Politics Foundation](http://www.participatorypolitics.org/).

## Copyright

This gem re-uses code from [fog](https://github.com/fog/fog), released under the MIT license.

Copyright (c) 2012 Open North Inc., released under the MIT license
