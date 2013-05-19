# coding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'multi_mail/sendgrid/receiver'

describe MultiMail::Receiver::SendGrid do
  context 'after initialization' do
    let :service do
      MultiMail::Receiver.new(:provider => :sendgrid)
    end

    def params(fixture, encoding = 'UTF-8')
      MultiMail::Receiver::SendGrid.parse(response('sendgrid', fixture, false, encoding))
    end

    describe '#transform' do
      it 'should return a mail message' do
        messages = service.transform(params('valid'))
        messages.size.should == 1
        message = messages[0]

        # Headers
        message.date.should    == DateTime.parse('Mon, 15 Apr 2013 20:20:12 -0400')
        message.from.should    == ['james@opennorth.ca']
        message.to.should      == ['foo+bar@parolecitoyenne.com']
        message.subject.should == 'Test'

        # Body
        message.multipart?.should            == true
        # @note SendGrid adds additional HTML parts as attachments, which is
        # sensible, but it does not match the behavior of other email APIs.
        message.parts.size.should            == 6
        message.parts[0].content_type.should == 'text/plain'
        message.parts[1].content_type.should == 'text/html; charset=UTF-8'
        message.parts[0].body.decoded.should == "bold text\n\n\n\nsome more bold text\n\n\n\nsome italic text\n\n> multiline\n> quoted\n> text\n\n\n--\nSignature block"
        # @note Due to a SendGrid bug, the HTML part is missing content.
        message.parts[1].body.decoded.should == %(<html><head></head><body style="word-wrap: break-word; -webkit-nbsp-mode: space; -webkit-line-break: after-white-space; "><b>bold text</b><div><br></div><div></div></body></html>)

        # HTML attachments
        message.parts[3].content_type.should == 'text/html; filename=msg-12415-313.html'
        message.parts[5].content_type.should == 'text/html; filename=msg-12415-314.html'
        message.parts[3].body.decoded.should == %(<html><body style="word-wrap: break-word; -webkit-nbsp-mode: space; -webkit-line-break: after-white-space; "><head></head><br><div></div><div><br></div><div><b>some more bold text</b></div><div><b><br></b></div><div><b></b></div></body></html>)
        message.parts[5].body.decoded.should == %(<html><head></head><body style="word-wrap: break-word; -webkit-nbsp-mode: space; -webkit-line-break: after-white-space; "><br><div><b></b></div><div><b><span class="Apple-style-span" style="font-weight: normal; "><br></span></b></div><div><b><span class="Apple-style-span" style="font-weight: normal; "><i>some italic text</i></span></b></div><div><b><span class="Apple-style-span" style="font-weight: normal; "><br></span></b></div><div><blockquote type="cite">multiline</blockquote><blockquote type="cite">quoted</blockquote><blockquote type="cite">text</blockquote></div><div><br></div><div>--</div><div>Signature block</div></body></html>)

        # Attachments
        attachment0 = message.attachments.find{|attachment| attachment.filename == 'foo.txt'}
        attachment1 = message.attachments.find{|attachment| attachment.filename == 'bar.txt'}
        attachment0.read.should == "Lorem ipsum dolor sit amet, consectetur adipiscing elit.\n"
        attachment1.read.should == "Nam accumsan euismod eros et rhoncus.\n"

        # Extra SendGrid parameters
        message['dkim'].value.should == 'none'
        message['SPF'].value.should == 'pass'
        message['spam_report'].value.should == "Spam detection software, running on the system \"mx3.sendgrid.net\", has\r\nidentified this incoming email as possible spam.  The original message\r\nhas been attached to this so you can view it (if it isn't spam) or label\r\nsimilar future email.  If you have any questions, see\r\nthe administrator of that system for details.\r\n\r\nContent preview:  bold text some more bold text some italic text [...] \r\n\r\nContent analysis details:   (-2.6 points, 5.0 required)\r\n\r\n pts rule name              description\r\n---- ---------------------- --------------------------------------------------\r\n-0.7 RCVD_IN_DNSWL_LOW      RBL: Sender listed at http://www.dnswl.org/, low\r\n                            trust\r\n                            [209.85.223.172 listed in list.dnswl.org]\r\n-1.9 BAYES_00               BODY: Bayes spam probability is 0 to 1%\r\n                            [score: 0.0000]\r\n 0.0 HTML_MESSAGE           BODY: HTML included in message\r\n\r\n"
        message['spam_score'].value.should == '-2.599'
      end

      # No postbin is capable of handling mixed encodings, and most fail to even
      # display the request. http://postbin.hackyon.com/ works best, but we
      # still need to hand-edit the response.
      it 'should respect encodings' do
        service.transform(params('encoding', 'WINDOWS-1252'))[0].text_part.decoded.should == 'World €'
      end
    end

    describe '#spam?' do
      it 'should return true if the response is spam' do
        message = service.transform(params('spam'))[0]
        service.spam?(message).should == true
      end

      it 'should return false if the response is ham' do
        message = service.transform(params('valid'))[0]
        service.spam?(message).should == false
      end
    end
  end
end
