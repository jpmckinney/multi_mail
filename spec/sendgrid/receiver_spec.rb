require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'multi_mail/sendgrid/receiver'

describe MultiMail::Receiver::SendGrid do
  context 'after initialization' do
    let :service do
      MultiMail::Receiver.new(:provider => :sendgrid)
    end

    def params(fixture)
      response('sendgrid',fixture)
      MultiMail::Receiver::SendGrid.parse(response('sendgrid', fixture))
    end

    describe '#transform' do
      it 'should return a mail message' do
        messages = service.transform(params('valid'))
        messages.size.should == 1
        message = messages[0]

        # Headers
        message.date.should    == DateTime.parse('Thu, 16 May 2013 13:33:35 -0400')
        message.from.should    == ['james@opennorth.ca']
        message.to.should      == ['foo+bar@parolecitoyenne.com']
        message.subject.should == 'Test'

        # Body
        message.multipart?.should            == true
        message.parts.size.should            == 6
        message.parts[0].content_type.should == 'text/plain'
        message.parts[0].body.decoded.should == "bold text\n\n\n\nsome more bold text\n\n\n\nsome italic text\n\n> multiline\n> quoted\n> text\n\n\n--\nSignature block"
        message.parts[1].content_type.should == 'text/html; charset=UTF-8'
        message.parts[1].body.decoded.should == '<html><head></head><body style="word-wrap: break-word; -webkit-nbsp-mode: space; -webkit-line-break: after-white-space; "><b>bold text</b><div><br></div><div></div></body></html>'
        # Attachments
        attachment0 = message.attachments.find{|attachment| attachment.filename == 'foo.txt'}
        attachment0.read.should == "Lorem ipsum dolor sit amet, consectetur adipiscing elit.\n"
        attachment1 = message.attachments.find{|attachment| attachment.filename == 'bar.txt'}
        attachment1.read.should == "Nam accumsan euismod eros et rhoncus.\n"
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