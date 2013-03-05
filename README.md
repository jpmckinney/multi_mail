# MultiMail: easily switch between email APIs

[![Build Status](https://secure.travis-ci.org/opennorth/multi_mail.png)](http://travis-ci.org/opennorth/multi_mail)
[![Dependency Status](https://gemnasium.com/opennorth/multi_mail.png)](https://gemnasium.com/opennorth/multi_mail)
[![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/opennorth/multi_mail)

Many providers – including [Cloudmailin](http://www.cloudmailin.com/), [Mailgun](http://www.mailgun.com/), [Mandrill](http://mandrill.com/), [Postmark](http://postmarkapp.com/) and [SendGrid](http://sendgrid.com/) – offer APIs to send, receive, parse and forward email. MultiMail lets you easily switch between these APIs.

## Usage

    require 'multi_mail'
    
    service = MultiMail::Receiver.new({
      :provider => 'mailgun',
      :mailgun_api_key => 'key-xxxxxxxxxxxxxxxxxxxxxxx-x-xxxxxx',
    })
    
    message = service.process data # raw POST data or params hash

`message` is an array of [Mail::Message](https://github.com/mikel/mail) instances.

## Supported APIs

Incoming email:

* [Mailgun](http://www.mailgun.com/)
* [Mandrill](http://mandrill.com/)

## Bugs? Questions?

This gem's main repository is on GitHub: [http://github.com/opennorth/multi_mail](http://github.com/opennorth/multi_mail), where your contributions, forks, bug reports, feature requests, and feedback are greatly welcomed.

## Acknowledgements

This gem is developed by [Open North](http://www.opennorth.ca/) through a partnership with the [Participatory Politics Foundation](http://www.participatorypolitics.org/).

## Copyright

This gem re-uses code from [fog](https://github.com/fog/fog), released under the MIT license.

Copyright (c) 2012 Open North Inc., released under the MIT license
