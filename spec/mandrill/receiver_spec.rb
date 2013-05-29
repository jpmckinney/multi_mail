require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'multi_mail/mandrill/receiver'

describe MultiMail::Receiver::Mandrill do
  context 'after initialization' do
    let :service do
      MultiMail::Receiver.new(
        :provider => :mandrill,
        :mandrill_webhook_key => 'rth_rywL9CWIIZBuwPQIWw',
        :mandrill_webhook_url => 'http://rackbin.herokuapp.com/'
        )
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

#      it 'should raise an error if parameters are missing' do
#        expect{ service.valid?(params('missing')) }.to raise_error(IndexError)
#      end
    end



    # @todo Add a spec for multiple Mandrill events.
    describe '#transform' do
      it 'should return a mail message' do
        messages = service.transform(params('valid'))
        #p messages
        messages.size.should == 1
        message = messages[0]
        
        # Headers
        message.date.should    == DateTime.parse('Mon, 29 May 2013 16:51:45 -04:00')
        message.from.should    == ['james@opennorth.ca']
        message.to.should      == ['foo+bar@govkit.org']
        message.subject.should == 'Test'

        # Body
        message.multipart?.should            == true
        message.parts.size.should            == 4
        message.parts[0].content_type.should == 'text/plain'
        message.parts[1].content_type.should == 'text/html; charset=UTF-8'
        # @note Mandrill adds a newline at the end of each part.
        message.parts[0].body.decoded.should == "bold text\n\n\n\nsome more bold text\n\n\n\nsome italic text\n\n> multiline\n> quoted\n> text\n\n\n--\nSignature block\n"
        message.parts[1].body.decoded.should == %(<html><head></head><body style="word-wrap: break-word; -webkit-nbsp-mode: space; -webkit-line-break: after-white-space; "><b>bold text</b><div><br></div><div></div></body></html><html><body style="word-wrap: break-word; -webkit-nbsp-mode: space; -webkit-line-break: after-white-space; "><head></head><br><div></div><div><br></div><div><b>some more bold text</b></div><div><b><br></b></div><div><b></b></div></body></html><html><head></head><body style="word-wrap: break-word; -webkit-nbsp-mode: space; -webkit-line-break: after-white-space; "><br><div><b></b></div><div><b><span class="Apple-style-span" style="font-weight: normal; "><br></span></b></div><div><b><span class="Apple-style-span" style="font-weight: normal; "><i>some italic text</i></span></b></div><div><b><span class="Apple-style-span" style="font-weight: normal; "><br></span></b></div><div><blockquote type="cite">multiline</blockquote><blockquote type="cite">quoted</blockquote><blockquote type="cite">text</blockquote></div><div><br></div><div>--</div><div>Signature block</div></body></html>)

        # Attachments
        attachment0 = message.attachments.find{|attachment| attachment.filename == 'foo.txt'}
        attachment1 = message.attachments.find{|attachment| attachment.filename == 'bar.txt'}
        attachment0.read.should == "Lorem ipsum dolor sit amet, consectetur adipiscing elit.\n\n"
        attachment1.read.should == "Nam accumsan euismod eros et rhoncus.\n\n"

        # Extra Mandrill parameters
        message['ts'].value.should == '1369860716'
        message['email'].value.should == 'foo+bar@govkit.org'
        message['dkim-signed'].value.should == 'false'
        message['dkim-valid'].value.should == 'false'
        message['spam_report-score'].value.should == '-0.7'
        message['spf-result'].value.should == 'pass'
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
