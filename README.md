# MultiMail: easily switch between incoming email APIs

[![Dependency Status](https://gemnasium.com/opennorth/multi_mail.png)](https://gemnasium.com/opennorth/multi_mail)
[![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/opennorth/multi_mail)

Many providers – including [Cloudmailin](http://www.cloudmailin.com/), [Mailgun](http://www.mailgun.com/), [Mandrill](http://mandrill.com/), [Postmark](http://postmarkapp.com/) and [SendGrid](http://sendgrid.com/) – offer APIs to receive, parse and forward incoming email to a URL. MultiMail lets you easily switch between these APIs.

## Usage

```ruby
require 'multi_mail'

service = MultiMail::Receiver.new({
  :provider => 'mailgun',
  :mailgun_api_key => 'key-xxxxxxxxxxxxxxxxxxxxxxx-x-xxxxxx',
})

message = service.process data # raw POST data or params hash
```

`message` is a [Mail::Message](https://github.com/mikel/mail) instance.

## Supported APIs

* [Mailgun](http://www.mailgun.com/)

## Bugs? Questions?

This gem's main repository is on GitHub: [http://github.com/opennorth/multi_mail](http://github.com/opennorth/multi_mail), where your contributions, forks, bug reports, feature requests, and feedback are greatly welcomed.

## Copyright

This gem re-uses code from [fog](https://github.com/fog/fog), released under the MIT license.

Copyright (c) 2012 Open North Inc., released under the MIT license
