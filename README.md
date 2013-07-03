# MultiMail: easily switch email APIs

[![Build Status](https://secure.travis-ci.org/opennorth/multi_mail.png)](http://travis-ci.org/opennorth/multi_mail)
[![Dependency Status](https://gemnasium.com/opennorth/multi_mail.png)](https://gemnasium.com/opennorth/multi_mail)
[![Coverage Status](https://coveralls.io/repos/opennorth/multi_mail/badge.png?branch=master)](https://coveralls.io/r/opennorth/multi_mail)
[![Code Climate](https://codeclimate.com/github/opennorth/multi_mail.png)](https://codeclimate.com/github/opennorth/multi_mail)

Many providers – including [Cloudmailin](http://www.cloudmailin.com/), [Mailgun](http://www.mailgun.com/), [Mandrill](http://mandrill.com/), [Postmark](http://postmarkapp.com/) and [SendGrid](http://sendgrid.com/) – offer APIs to send, receive, parse and forward email. MultiMail lets you easily switch between these APIs:

* [Cloudmailin](http://www.cloudmailin.com/): [Documentation](#cloudmailin)
* [Mailgun](http://www.mailgun.com/): [Documentation](#mailgun)
* [Mandrill](http://mandrill.com/): [Documentation](#mandrill)
* [Postmark](http://postmarkapp.com/): [Documentation](#postmark)
* [SendGrid](http://sendgrid.com/): [Documentation](#sendgrid)

## Usage

### Incoming

```ruby
require 'multi_mail'

# Create an object to consume webhook data.
service = MultiMail::Receiver.new(:provider => 'mandrill')

# Process the webhook data, whether it's raw POST data, a params hash, a Rack request, etc.
messages = service.process(data)
```

`messages` will be an array of [Mail::Message](https://github.com/mikel/mail) instances. Any additional parameters provided by an API are added to each message as a header. For example, Mailgun provides `stripped-text`, which is the message body without quoted parts or signature block. You can access it as `message['stripped-text'].value`.

### Outgoing

With MultiMail, you send a message the same way you do with the [Mail](https://github.com/mikel/mail#sending-an-email) gem. You just need to set the `delivery_method` for the message:

```ruby
require 'multi_mail'
require 'multi_mail/postmark/sender'

message = Mail.new do
  delivery_method MultiMail::Sender::Postmark, :api_key => 'your-api-key'
  ...
end

message.deliver
```

Alternatively, instead of setting the `delivery_method` during initialization, you can set it before delivery, kike:

```ruby
message = Mail.new do
  ...
end

message.delivery_method MultiMail::Sender::Postmark, :api_key => 'your-api-key'

message.deliver
```

If you are sending many messages, you can set a default `delivery_method` for all messages:

```ruby
Mail.defaults do
  delivery_method MultiMail::Sender::Postmark, :api_key => 'your-api-key'
end
```

If you want to inspect the API response, pass `:return_response => true` to `delivery_method` and use the `deliver!` method to send the message. Note that `deliver!` ignores Mail's `perform_deliveries` and `raise_delivery_errors` flags.

```ruby
message = Mail.new do
  delivery_method MultiMail::Sender::Postmark, :api_key => 'your-api-key', :return_response => true
  ...
end

message.deliver!
```

## Cloudmailin

```ruby
service = MultiMail::Receiver.new({
  :provider => 'cloudmailin',
})
```

The default HTTP POST format is `raw`. Add a `:http_post_format` option to change the HTTP POST format, with possible values of `"multipart"`, `"json"` or `"raw"` (default). For example:

```ruby
service = MultiMail::Receiver.new({
  :provider => 'cloudmailin',
  :http_post_format => 'raw',
})
```

See [Cloudmailin's documentation](http://docs.cloudmailin.com/http_post_formats/) for these additional parameters provided by the API:

* `reply_plain`
* `spf-result`

**Note:** [MultiMail doesn't yet support Cloudmailin's URL attachments (attachment stores).](https://github.com/opennorth/multi_mail/issues/11) Please use regular attachments (always the case if you use the `raw` format).

## Mailgun

### Incoming

```ruby
service = MultiMail::Receiver.new({
  :provider => 'mailgun',
})
```

To check whether a request originates from Mailgun, add the `:mailgun_api_key` option:

```ruby
service = MultiMail::Receiver.new({
  :provider => 'mailgun',
  :mailgun_api_key => 'key-xxxxxxxxxxxxxxxxxxxxxxx-x-xxxxxx',
})
```

If you are using the [raw MIME format](http://documentation.mailgun.com/user_manual.html#mime-messages-parameters), add a `:http_post_format => 'raw'` option:

```ruby
service = MultiMail::Receiver.new({
  :provider => 'mailgun',
  :mailgun_api_key => 'key-xxxxxxxxxxxxxxxxxxxxxxx-x-xxxxxx',
  :http_post_format => 'raw',
})
```

See [Mailgun's documentation](http://documentation.mailgun.net/user_manual.html#parsed-messages-parameters) for these additional parameters provided by the API:

* `stripped-text`
* `stripped-signature`
* `stripped-html`
* `content-id-map`

### Outgoing
    service = MultiMail::Sender.new({
      :provider => 'mailgun',
      :api_key => key-xxxxxxxxxxxxxxxxxxxxxxx-x-xxxxxx,
      :domain_name => yourdomain.mailgun.org,
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

## Mandrill

### Incoming

```ruby
service = MultiMail::Receiver.new({
  :provider => 'mandrill',
})
```

To check whether a request originates from Mandrill, add the `:mandrill_webhook_key` and `:mandrill_webhook_url` options:

```ruby
service = MultiMail::Receiver.new({
  :provider => 'mandrill',
  :mandrill_webhook_key => 'xxxxxxxxxxxxxxxxxxxxxx',
  :mandrill_webhook_url => 'http://example.com/post',
})
```
You can get your webhook key from [Mandrill's Webhooks Settings](https://mandrillapp.com/settings/webhooks).

The default SpamAssassin score needed to flag an email as spam is `5`. Add a `:spamassassin_threshold` option to increase or decrease it:

```ruby
service = MultiMail::Receiver.new({
  :provider => 'mandrill',
  :spamassassin_threshold => 4.5,
})
```

See [Mandrill's documentation](http://help.mandrill.com/entries/22092308-What-is-the-format-of-inbound-email-webhooks-) for these additional parameters provided by the API:

* `ts`
* `email`
* `dkim-signed`
* `dkim-valid`
* `spam_report-score`
* `spf-result`

### Outgoing

```ruby
require 'multi_mail/mandrill/sender'

Mail.deliver do
  delivery_method MultiMail::Sender::Mandrill, :api_key => 'your-api-key'
  ...
end
```

You may pass additional arguments to `delivery_method` to take advantage of Mandrill-specific features (see [Mandrill's documentation](https://mandrillapp.com/api/docs/messages.ruby.html#method-send)):

`important`                 | `merge`                     |
`track_opens`               | `global_merge_vars`         |
`track_clicks`              | `merge_vars`                |
`auto_text`                 | `tags`                      |
`auto_html`                 | `google_analytics_domains`  |
`inline_css`                | `google_analytics_campaign` |
`url_strip_qs`              | `metadata`                  |
`preserve_recipients`       | `recipient_metadata`        |
`bcc_address`               | `async`                     |
`tracking_domain`           | `ip_pool`                   |
`signing_domain`            | `send_at`                   |

## Postmark

### Incoming

```ruby
service = MultiMail::Receiver.new({
  :provider => 'postmark',
})
```

See [Postmark's documentation](http://developer.postmarkapp.com/developer-inbound-parse.html#mailboxhash) for these additional parameters provided by the API:

* `MailboxHash`
* `MessageID`
* `Tag`

### Outgoing

MultiMail depends on the `postmark` gem for its Postmark integration. MultiMail implements a simple wrapper around Postmark's [existing integration](https://github.com/wildbit/postmark-gem#using-postmark-with-the-mail-library) with the Mail gem, to be consistent with the other APIs:

```ruby
require 'multi_mail/postmark/sender'

Mail.deliver do
  delivery_method MultiMail::Sender::Postmark, :api_key => 'your-api-key'
  ...
end
```

## SendGrid

### Incoming

```ruby
service = MultiMail::Receiver.new({
  :provider => 'sendgrid',
})
```

The default SpamAssassin score needed to flag an email as spam is `5`. Add a `:spamassassin_threshold` option to increase or decrease it. For example:

```ruby
service = MultiMail::Receiver.new({
  :provider => 'sendgrid',
  :spamassassin_threshold => 4.5,
})
```

See [SendGrid's documentation](http://sendgrid.com/docs/API_Reference/Webhooks/parse.html) for these additional parameters provided by the API:

* `dkim`
* `SPF`
* `spam_report`
* `spam_score`

### Outgoing

```ruby
require 'multi_mail/sendgrid/sender'

Mail.deliver do
  delivery_method MultiMail::Sender::SendGrid, :api_user => 'username', :api_key => 'password'
  ...
end
```

You may pass additional arguments to `delivery_method` to take advantage of SendGrid-specific features (see [SendGrid's documentation](http://sendgrid.com/docs/API_Reference/Web_API/mail.html)):

* `x-smtpapi`

## Bugs? Questions?

This gem's main repository is on GitHub: [http://github.com/opennorth/multi_mail](http://github.com/opennorth/multi_mail), where your contributions, forks, bug reports, feature requests, and feedback are greatly welcomed.

## Acknowledgements

This gem is developed by [Open North](http://www.opennorth.ca/) through a partnership with the [Participatory Politics Foundation](http://www.participatorypolitics.org/).

## Copyright

This gem re-uses code from [fog](https://github.com/fog/fog), released under the MIT license.

Copyright (c) 2012 Open North Inc., released under the MIT license
