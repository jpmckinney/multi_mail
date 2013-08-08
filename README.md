# MultiMail: easily switch email APIs

[![Build Status](https://secure.travis-ci.org/opennorth/multi_mail.png)](http://travis-ci.org/opennorth/multi_mail)
[![Dependency Status](https://gemnasium.com/opennorth/multi_mail.png)](https://gemnasium.com/opennorth/multi_mail)
[![Coverage Status](https://coveralls.io/repos/opennorth/multi_mail/badge.png?branch=master)](https://coveralls.io/r/opennorth/multi_mail)
[![Code Climate](https://codeclimate.com/github/opennorth/multi_mail.png)](https://codeclimate.com/github/opennorth/multi_mail)

Many providers offer APIs to send, receive, and parse email. MultiMail lets you easily switch between these APIs, and integrates tightly with the [Mail](https://github.com/mikel/mail) gem.

* [Cloudmailin](http://www.cloudmailin.com/): [Example](#cloudmailin)
* [Mailgun](http://www.mailgun.com/): [Example](#mailgun)
* [Mandrill](http://mandrill.com/): [Example](#mandrill)
* [Postmark](http://postmarkapp.com/): [Example](#postmark)
* [SendGrid](http://sendgrid.com/): [Example](#sendgrid)

## Usage

### Incoming

```ruby
require 'multi_mail'

# Create an object to consume the webhook data.
service = MultiMail::Receiver.new(:provider => 'mandrill')

# Process the webhook data, whether it's raw POST data, a params hash, a Rack request, etc.
messages = service.process(data)
```

`messages` will be an array of [Mail::Message](https://github.com/mikel/mail) instances.

Any non-standard parameters provided by an API are added to each message as a header. For example, Mailgun provides `stripped-text`, which is the message body without quoted parts or signature block. You can access it as `message['stripped-text'].value`.

### Outgoing

With MultiMail, you send a message the same way you do with the [Mail](https://github.com/mikel/mail#sending-an-email) gem. Just set `delivery_method`:

```ruby
require 'multi_mail'

message = Mail.new do
  delivery_method MultiMail::Sender::Postmark, :api_key => 'your-api-key'
  ...
end

message.deliver
```

Alternatively, instead of setting `delivery_method` during initialization, you can set it before delivery:

```ruby
message = Mail.new do
  ...
end

message.delivery_method MultiMail::Sender::Postmark, :api_key => 'your-api-key'

message.deliver
```

Or, if you are sending many messages, you can set a default `delivery_method` for all messages:

```ruby
Mail.defaults do
  delivery_method MultiMail::Sender::Postmark, :api_key => 'your-api-key'
end
```

#### Track opens and clicks

Mailgun and Mandrill allow you to set open tracking and click tracking on a per-message basis:

```ruby
require 'multi_mail'

message = Mail.new do
  delivery_method MultiMail::Sender::Mailgun,
    :api_key => 'your-api-key',
    :domain => 'your-domain.mailgun.org',
    :track => {
      :opens => true,
      :clicks => false,
    }
  ...
end

message.deliver
```

[Mailgun](http://documentation.mailgun.com/user_manual.html#tracking-clicks) and [Mandrill](http://help.mandrill.com/entries/21721852-Why-aren-t-clicks-being-tracked-) track whether a recipient has clicked a link in a message by rewriting its URL. If want to rewrite URLs in HTML parts only (leaving URLs as-is in text parts) use `:clicks => 'htmlonly'` if you are using Mailgun; if you are using Mandrill, do not set `:clicks` and instead configure click tracking globally in your [Mandrill sending options](https://mandrillapp.com/settings/sending-options).

#### Inspect the API response

Pass `:return_response => true` to `delivery_method` and use the `deliver!` method to send the message:

```ruby
message = Mail.new do
  delivery_method MultiMail::Sender::Postmark, :api_key => 'your-api-key', :return_response => true
  ...
end

message.deliver!
```

Note that the `deliver!` method ignores Mail's `perform_deliveries` and `raise_delivery_errors` flags.

## Cloudmailin

### Incoming

```ruby
service = MultiMail::Receiver.new({
  :provider => 'cloudmailin',
})
```

The default HTTP POST format is `raw`. Add a `:http_post_format` option to change the HTTP POST format, with possible values of `"multipart"`, `"json"` or `"raw"` (default):

```ruby
service = MultiMail::Receiver.new({
  :provider => 'cloudmailin',
  :http_post_format => 'raw',
})
```

See [Cloudmailin's documentation](http://docs.cloudmailin.com/http_post_formats/) for these additional parameters provided by the API:

* `reply_plain`
* `spf-result`

**Note:** [MultiMail doesn't yet support Cloudmailin's URL attachments (attachment stores).](https://github.com/opennorth/multi_mail/issues/11) Please use regular attachments (always the case if you use the default `raw` format).

## Mailgun

### Incoming

```ruby
service = MultiMail::Receiver.new({
  :provider => 'mailgun',
})
```

To check that a request originates from Mailgun, add a `:mailgun_api_key` option:

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
  :http_post_format => 'raw',
})
```

See [Mailgun's documentation](http://documentation.mailgun.net/user_manual.html#parsed-messages-parameters) for these additional parameters provided by the API:

* `stripped-text`
* `stripped-signature`
* `stripped-html`
* `content-id-map`

### Outgoing

```ruby
Mail.deliver do
  delivery_method MultiMail::Sender::Mailgun, :api_key => 'your-api-key', :domain => 'your-domain.mailgun.org'
  ...
end
```

You may pass additional arguments to `delivery_method` to use Mailgun-specific features ([see docs](http://documentation.mailgun.com/api-sending.html)):

* `o:tag`
* `o:campaign`
* `o:dkim`
* `o:deliverytime`
* `o:testmode`
* `o:tracking`
* `v:`

## Mandrill

### Incoming

```ruby
service = MultiMail::Receiver.new({
  :provider => 'mandrill',
})
```

To check that a request originates from Mandrill, add `:mandrill_webhook_key` and `:mandrill_webhook_url` options (you can get your webhook key from [Mandrill's Webhooks Settings](https://mandrillapp.com/settings/webhooks)):

```ruby
service = MultiMail::Receiver.new({
  :provider => 'mandrill',
  :mandrill_webhook_key => 'xxxxxxxxxxxxxxxxxxxxxx',
  :mandrill_webhook_url => 'http://example.com/post',
})
```

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
Mail.deliver do
  delivery_method MultiMail::Sender::Mandrill, :api_key => 'your-api-key'
  ...
end
```

You may pass additional arguments to `delivery_method` to use Mandrill-specific features ([see docs](https://mandrillapp.com/api/docs/messages.ruby.html#method-send)):

* `important`
* `auto_text` and `auto_html`
* `inline_css`
* `url_strip_qs`
* `preserve_recipients`
* `bcc_address`
* `tracking_domain` and `signing_domain`
* `merge`, `global_merge_vars` and `merge_vars`
* `tags`
* `google_analytics_domains` and `google_analytics_campaign`
* `metadata` and `recipient_metadata`
* `async`
* `ip_pool`
* `send_at`

## Postmark

### Incoming

```ruby
service = MultiMail::Receiver.new({
  :provider => 'postmark',
})
```

See [Postmark's documentation](http://developer.postmarkapp.com/developer-inbound-parse.html#mailboxhash) for these additional parameters provided by the API:

* `MailboxHash`
* `Tag`

### Outgoing

```ruby
Mail.deliver do
  delivery_method MultiMail::Sender::Postmark, :api_key => 'your-api-key'
  ...
end
```

You may also pass a `Tag` option to `delivery_method` ([see Postmark's documentation](http://developer.postmarkapp.com/developer-build.html#message-format)).

## SendGrid

### Incoming

```ruby
service = MultiMail::Receiver.new({
  :provider => 'sendgrid',
})
```

The default SpamAssassin score needed to flag an email as spam is `5`. Add a `:spamassassin_threshold` option to increase or decrease it:

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
Mail.deliver do
  delivery_method MultiMail::Sender::SendGrid, :api_user => 'username', :api_key => 'password'
  ...
end
```

You may also pass a `x-smtpapi` option to `delivery_method` ([see SendGrid's documentation](http://sendgrid.com/docs/API_Reference/Web_API/mail.html)).

## Bugs? Questions?

This gem's main repository is on GitHub: [http://github.com/opennorth/multi_mail](http://github.com/opennorth/multi_mail), where your contributions, forks, bug reports, feature requests, and feedback are greatly welcomed.

## Acknowledgements

This gem is developed by [Open North](http://www.opennorth.ca/) through a partnership with the [Participatory Politics Foundation](http://www.participatorypolitics.org/).

## Copyright

This gem re-uses code from [fog](https://github.com/fog/fog), released under the MIT license.

Copyright (c) 2012 Open North Inc., released under the MIT license
