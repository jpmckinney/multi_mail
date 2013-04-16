require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'multi_mail/mandrill/receiver'

describe MultiMail::Receiver::Mandrill do
  context 'after initialization' do
    let :service do
      MultiMail::Receiver.new(:provider => :mandrill)
    end

    def params(fixture)
      MultiMail::Receiver::Mandrill.parse(response('mandrill', fixture))
    end

    describe '#valid?' do
      it 'should return true if the response is valid' do
        service.valid?(params('valid')).should == true
      end

      it 'should return false if the response is invalid' do
        service.valid?(params('invalid')).should == false
      end

      it 'should raise an error if parameters are missing' do
        expect{ service.valid?(params('missing')) }.to raise_error(IndexError)
      end
    end

    describe '#transform' do
      it 'should return a mail message' do
        pending
        message = service.transform(params('valid'))[0]

        # Headers
        message.date.should    == DateTime.parse('Thu, 15 Apr 2013 20:20:12 -04:00')
        message.from.should    == ['james@opennorth.ca']
        message.to.should      == ['foo+bar@govkit.org']
        message.subject.should == 'Test'

        # Body
        message.multipart?.should            == true
        message.parts.size.should            == 4
        message.parts[0].content_type.should == 'text/plain'
        message.parts[1].content_type.should == 'text/html; charset=UTF-8'
        message.parts[0].body.decoded.should == "bold text\n\n\n\nsome more bold text\n\n\n\nsome italic text\n\n> multiline\n> quoted\n> text\n\n\n--\nSignature block"
        message.parts[1].body.decoded.should == %(<html><head></head><body style="word-wrap: break-word; -webkit-nbsp-mode: space; -webkit-line-break: after-white-space; "><b>bold text</b><div><br></div><div></div></body></html><html><body style="word-wrap: break-word; -webkit-nbsp-mode: space; -webkit-line-break: after-white-space; "><head></head><br><div></div><div><br></div><div><b>some more bold text</b></div><div><b><br></b></div><div><b></b></div></body></html><html><head></head><body style="word-wrap: break-word; -webkit-nbsp-mode: space; -webkit-line-break: after-white-space; "><br><div><b></b></div><div><b><span class="Apple-style-span" style="font-weight: normal; "><br></span></b></div><div><b><span class="Apple-style-span" style="font-weight: normal; "><i>some italic text</i></span></b></div><div><b><span class="Apple-style-span" style="font-weight: normal; "><br></span></b></div><div><blockquote type="cite">multiline</blockquote><blockquote type="cite">quoted</blockquote><blockquote type="cite">text</blockquote></div><div><br></div><div>--</div><div>Signature block</div></body></html>)

        # Attachments
        message.attachments[0].filename.should == 'foo.txt'
        message.attachments[0].read.should == "Lorem ipsum dolor sit amet, consectetur adipiscing elit.\n"
        message.attachments[1].filename.should == 'bar.txt'
        message.attachments[1].read.should == "Nam accumsan euismod eros et rhoncus.\n"

        # Extra Mandrill parameters
        message['ts'].value.should == '1356639931'
        message['email'].value.should == 'foo+bar@govkit.org'
        message['dkim-signed'].value.should == 'true'
        message['dkim-valid'].value.should == 'true'
        message['spam_report-core'].value.should == '0'
        message['spf-result'].value.should == 'pass'
      end
    end

    describe '#spam?' do
      it 'should return true if the response is spam' do
        pending
        message = service.transform(params('spam'))[0]
        service.spam?(message).should == true
      end

      it 'should return false if the response is ham' do
        pending
        message = service.transform(params('valid'))[0]
        service.spam?(message).should == false
      end
    end
  end
end
