require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'multi_mail/postmark/receiver'

describe MultiMail::Receiver::Postmark do
  context 'after initialization' do
    let :service do
      MultiMail::Receiver.new(:provider => :postmark)
    end

    def params(fixture)
      MultiMail::Receiver::Postmark.parse(response('postmark', fixture))
    end

    describe '#transform' do
      it 'should return a mail message' do
        messages = service.transform(params('valid'))
        messages.size.should == 1
        message = messages[0]

        # Headers
        message.date.should    == DateTime.parse('Mon, 15 Apr 2013 20:20:12 -0400')
        message.from.should    == ['james@opennorth.ca']
        message.to.should      == ['4354473e2e6ab001fa836f627a54004e@inbound.postmarkapp.com']
        message.subject.should == 'Test'

        # Body
        message.multipart?.should            == true
        message.parts.size.should            == 4
        message.parts[0].content_type.should == 'text/plain'
        message.parts[1].content_type.should == 'text/html; charset=UTF-8'
        message.parts[0].body.decoded.should == "bold text\n\n\n\nsome more bold text\n\n\n\nsome italic text\n\n> multiline\n> quoted\n> text\n\n\n--\nSignature block"
        # @note Due to a Postmark bug, the HTML part is missing content.
        message.parts[1].body.decoded.should == %(<html><head></head><body style="word-wrap: break-word; -webkit-nbsp-mode: space; -webkit-line-break: after-white-space; "><b>bold text</b><div><br></div><div></div></body></html>)

        # Attachments
        attachment0 = message.attachments.find{|attachment| attachment.filename == 'foo.txt'}
        attachment1 = message.attachments.find{|attachment| attachment.filename == 'bar.txt'}
        attachment0.read.should == "Lorem ipsum dolor sit amet, consectetur adipiscing elit.\n"
        attachment1.read.should == "Nam accumsan euismod eros et rhoncus.\n"

        # Extra Postmark parameters
        message['MailboxHash'].should be_nil
        message['MessageID'].value.should == '61c7c8b8-ba7e-43c3-b9ad-0ba865e8caa2'
        message['Tag'].should be_nil
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
