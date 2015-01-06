# MultiMail: Easily switch email APIs

[![Gem Version](https://badge.fury.io/rb/multi_mail.svg)](http://badge.fury.io/rb/multi_mail)
[![Build Status](https://secure.travis-ci.org/jpmckinney/multi_mail.png)](http://travis-ci.org/jpmckinney/multi_mail)
[![Dependency Status](https://gemnasium.com/jpmckinney/multi_mail.png)](https://gemnasium.com/jpmckinney/multi_mail)
[![Coverage Status](https://coveralls.io/repos/jpmckinney/multi_mail/badge.png?branch=master)](https://coveralls.io/r/jpmckinney/multi_mail)
[![Code Climate](https://codeclimate.com/github/jpmckinney/multi_mail.png)](https://codeclimate.com/github/jpmckinney/multi_mail)

Many providers offer APIs to send, receive, and parse email. MultiMail lets you easily switch between these APIs, and integrates tightly with the [Mail](https://github.com/mikel/mail) gem.

* [Cloudmailin](http://www.cloudmailin.com/): [Example](#cloudmailin)
* [Mailgun](http://www.mailgun.com/): [Example](#mailgun)
* [Mandrill](http://mandrill.com/): [Example](#mandrill)
* [Postmark](http://postmarkapp.com/): [Example](#postmark)
* [SendGrid](http://sendgrid.com/): [Example](#sendgrid)
* MTA like [Postfix](http://en.wikipedia.org/wiki/Postfix_\(software\)) or [qmail](http://en.wikipedia.org/wiki/Qmail): [Example](#mta)

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

  to 'user@wookiecookies.com'
  from 'Chewbacca <chewy@wookiecookies.com>'
  subject 'How About Some Cookies?'

  text_part do
    body 'I am just some plain text!'
  end

  html_part do
    content_type 'text/html; charset=UTF-8'
    body '<html><body><h1>I am a header</h1><p>And I am a paragraph</p></body></html>'
  end
end

message.deliver
```

Alternatively, instead of setting `delivery_method` during initialization, you can set it before delivery:

```ruby
message = Mail.new do
  to 'user@wookiecookies.com'
  from 'Chewbacca <chewy@wookiecookies.com>'
  subject 'How About Some Cookies?'

  text_part do
    body 'I am just some plain text!'
  end

  html_part do
    content_type 'text/html; charset=UTF-8'
    body '<html><body><h1>I am a header</h1><p>And I am a paragraph</p></body></html>'
  end
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

#### Tagging

Mailgun, Mandrill and Postmark allow you to tag messages in order to accumulate statistics by tag, which will be accessible through their user interface:

```ruby
require 'multi_mail'

message = Mail.new do
  delivery_method MultiMail::Sender::Mandrill, :api_key => 'your-api-key'

  tag 'signup'
  tag 'promotion'

  ...
end

message.deliver
```

Mailgun accepts at most [3 tags](http://documentation.mailgun.com/user_manual.html#tagging) and Postmark at most one tag.

#### Track opens and clicks

Mailgun, Mandrill and Postmark allow you to set open tracking, and Mailgun and Mandrill allow you to set click tracking on a per-message basis:

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

If you are using an [Amazon S3 attachment store](http://docs.cloudmailin.com/receiving_email/attachments/), add a `:attachment_store => true` option. You must set the attachment store's permission setting to "Public Read".

```ruby
service = MultiMail::Receiver.new({
  :provider => 'cloudmailin',
  :http_post_format => 'multipart',
  :attachment_store => true,
})
```

See [Cloudmailin's documentation](http://docs.cloudmailin.com/http_post_formats/) for these additional parameters provided by the API:

* `reply_plain`
* `spf-result`

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
  
  to _to_
  from _from_
  subject _subject_

  text_part do
    body _text_
  end

  html_part do
    content_type 'text/html; charset=UTF-8'
    body _html_
  end
end
```

You may pass additional arguments to `delivery_method` to use Mailgun-specific features ([see docs](http://documentation.mailgun.com/api-sending.html)):

* `o:campaign`
* `o:dkim`
* `o:deliverytime`
* `o:testmode`
* `o:tracking`
* `v:`

```ruby
Mail.deliver do
  delivery_method MultiMail::Sender::Mailgun, :api_key => 'your-api-key', :domain => 'your-domain.mailgun.org',
                  :o:campaign => 'campaign', :o:dkim => 'yes (or no)',...
  ...
end
```

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
  
  to _to_
  from _from_email_ + _from_name_
  subject _subject_

  text_part do
    body _text_
  end

  html_part do
    content_type 'text/html; charset=UTF-8'
    body _html_
  end
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
* `google_analytics_domains` and `google_analytics_campaign`
* `metadata` and `recipient_metadata`
* `async`
* `ip_pool`
* `send_at`

```ruby
Mail.deliver do
  delivery_method MultiMail::Sender::Mandrill, :api_key => 'your-api-key',
                  :async => true, :ip_pool => 'main_pool', ...
  ...
end
```

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
  
  to _To_
  from _From_
  subject _Subject_

  text_part do
    body _TextBody_
  end

  html_part do
    content_type 'text/html; charset=UTF-8'
    body _HtmlBody_
  end
end
```

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
  
  to _to_
  from _from_ + _fromname_
  subject _subject_

  text_part do
    body _text_
  end

  html_part do
    content_type 'text/html; charset=UTF-8'
    body _html_
  end
end
```

You may also pass a `x-smtpapi` option to `delivery_method` ([see SendGrid's documentation](http://sendgrid.com/docs/API_Reference/Web_API/mail.html)).

```ruby
Mail.deliver do
  delivery_method MultiMail::Sender::SendGrid, :api_user => 'username', :api_key => 'password',
                  :x-smtpapi => '{ "some_json" : "with_some_data" }'
  ...
end
```


## MTA

### Incoming

If you are switching from an email API to Postfix or qmail, the simplest option is to continue sending messages to your application's webhook URL.

Your Postfix configuration may look like:

    # /etc/postfix/virtual
    incoming@myapp.com myappalias

    # /etc/mail/aliases
    myappalias: "| multi_mail_post --secret my-secret-string http://www.myapp.com/post"

Your qmail configuration may look like:

    # /var/qmail/mailnames/myapp.com/.qmail-incoming
    | multi_mail_post --secret my-secret-string http://www.myapp.com/post

In your application, you would use the `simple` provider:

```ruby
service = MultiMail::Receiver.new({
  :provider => 'simple',
  :secret => 'my-secret-string',
})
```

It's recommended to use a secret key, to ensure that the requests are sent by Postfix and qmail and not by other sources on the internet.

This gem re-uses code from [fog](https://github.com/fog/fog), released under the MIT license.

Copyright (c) 2012 James McKinney, released under the MIT license
