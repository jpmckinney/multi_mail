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
        message.date.should    == DateTime.parse('Thu, 27 Dec 2012 15:25:37 -0500')
        message.from.should    == ['james@opennorth.ca']
        message.to.should      == ['foo+bar@govkit.org']
        message.subject.should == 'Test'

        # Body
        message.multipart?.should            == true
        message.parts.size.should            == 2
        message.parts[0].content_type.should == 'text/plain'
        message.parts[0].body.should         == "bold text\n\n\n> multiline\n> quoted\n> text\n\n--\nSignature block\n"
        message.parts[1].content_type.should == 'text/html; charset=UTF-8'
        message.parts[1].body.should         == %(<html><head></head><body style="word-wrap: break-word; -webkit-nbsp-mode: space; -webkit-line-break: after-white-space; "><div><b>bold text</b></div><div><br></div><div><blockquote type="cite"></blockquote></div><div><blockquote type="cite">multiline</blockquote></div><blockquote type="cite"><div>quoted</div><div>text</div></blockquote><br><div>--</div><div>Signature block</div></body></html>\n)

        # Attachments
        message.attachments[0].filename.should == 'foo.txt'
        message.attachments[0].read.should == "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed fringilla consectetur rhoncus. Nunc mattis mattis urna quis molestie. Quisque ut mattis nisl. Donec neque felis, porta quis condimentum eu, pharetra non libero.\n"
        message.attachments[1].filename.should == 'bar.txt'
        message.attachments[1].read.should == "Nam accumsan euismod eros et rhoncus. Phasellus fermentum erat id lacus egestas vulputate. Pellentesque eu risus dui, id scelerisque neque. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus.\n"

        # Extra Mandrill parameters
        message['ts'].value.should == '1356639931'
        message['email'].value.should == 'foo+bar@govkit.org'
        message['dkim-signed'].value.should == 'true'
        message['dkim-valid'].value.should == 'true'
        message['X-Mailgun-SScore'].value.should == '0'
        message['X-Mailgun-Spf'].value.should == 'pass'
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
