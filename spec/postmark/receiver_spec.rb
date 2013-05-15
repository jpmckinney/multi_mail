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

    describe '#transform' do
      it 'should return a mail message' do
 #       messages = service.transform(params('valid'))
 #       messages.size.should == 1
 #       message = messages[0]
        message = service.transform(params('valid'))

        # Headers
        message.date.should    == DateTime.parse('Tue, 14 May 2013 15:30:36 -0400')
        message.from.should    == ['alexi@opennorth.ca']
        message.to.should      == ['4354473e2e6ab001fa836f627a54004e@inbound.postmarkapp.com']
        message.subject.should == 'Test'

        # Body
        message.multipart?.should            == true
        message.parts.size.should            == 3
        message.parts[0].content_type.should == 'text/plain'
        message.parts[0].body.decoded.should == "\nbold text\n\n\n\nsome more bold text\n\n\n\nsome italic text\n\n> multiline\n> quoted\n> text\n\n\n--\nSignature block\n\n"
        message.parts[1].content_type.should == 'text/html; charset=UTF-8'
        message.parts[1].body.decoded.should == "&lt;html&gt;&lt;head&gt;&lt;meta http-equiv=&quot;Content-Type&quot; content=&quot;text\/html charset=us-ascii&quot;&gt;&lt;base href=&quot;file:\/\/\/Users\/alexio\/Desktop\/test.html&quot;&gt;&lt;\/head&gt;&lt;body style=&quot;word-wrap: break-word; -webkit-nbsp-mode: space; -webkit-line-break: after-white-space; &quot;&gt;&lt;span class=&quot;Apple-Mail-URLShareWrapperClass&quot; contenteditable=&quot;false&quot;&gt;&lt;span class=&quot;Apple-Mail-URLShareUserContentTopClass&quot; style=&quot;font-family: Helvetica !important; font-size: 12px !important; line-height: 14px !important; color: black !important; text-align: left !important; &quot; applecontenteditable=&quot;true&quot;&gt;&lt;br&gt;&lt;\/span&gt;&lt;span class=&quot;Apple-Mail-URLShareSharedContentClass&quot; style=&quot;position: relative !important; &quot; applecontenteditable=&quot;true&quot;&gt;&lt;base href=&quot;file:\/\/\/Users\/alexio\/Desktop\/test.html&quot;&gt;&lt;div style=&quot;word-wrap: break-word; -webkit-nbsp-mode: space; -webkit-line-break: after-white-space; &quot;&gt;&lt;b&gt;bold text&lt;\/b&gt;&lt;div&gt;&lt;br&gt;&lt;\/div&gt;&lt;div&gt;&lt;\/div&gt;&lt;br&gt;&lt;div&gt;&lt;\/div&gt;&lt;div&gt;&lt;br&gt;&lt;\/div&gt;&lt;div&gt;&lt;b&gt;some more bold text&lt;\/b&gt;&lt;\/div&gt;&lt;div&gt;&lt;b&gt;&lt;br&gt;&lt;\/b&gt;&lt;\/div&gt;&lt;div&gt;&lt;b&gt;&lt;\/b&gt;&lt;\/div&gt;&lt;br&gt;&lt;div&gt;&lt;b&gt;&lt;\/b&gt;&lt;\/div&gt;&lt;div&gt;&lt;b&gt;&lt;span class=&quot;Apple-style-span&quot; style=&quot;font-weight: normal; &quot;&gt;&lt;br&gt;&lt;\/span&gt;&lt;\/b&gt;&lt;\/div&gt;&lt;div&gt;&lt;b&gt;&lt;span class=&quot;Apple-style-span&quot; style=&quot;font-weight: normal; &quot;&gt;&lt;i&gt;some italic text&lt;\/i&gt;&lt;\/span&gt;&lt;\/b&gt;&lt;\/div&gt;&lt;div&gt;&lt;b&gt;&lt;span class=&quot;Apple-style-span&quot; style=&quot;font-weight: normal; &quot;&gt;&lt;br&gt;&lt;\/span&gt;&lt;\/b&gt;&lt;\/div&gt;&lt;div&gt;&lt;blockquote type=&quot;cite&quot;&gt;multiline&lt;\/blockquote&gt;&lt;blockquote type=&quot;cite&quot;&gt;quoted&lt;\/blockquote&gt;&lt;blockquote type=&quot;cite&quot;&gt;text&lt;\/blockquote&gt;&lt;\/div&gt;&lt;div&gt;&lt;br&gt;&lt;\/div&gt;&lt;div&gt;--&lt;\/div&gt;&lt;div&gt;Signature block&lt;\/div&gt;&lt;\/div&gt;&lt;\/span&gt;&lt;span class=&quot;Apple-Mail-URLShareUserContentBottomClass&quot; style=&quot;font-family: Helvetica !important; font-size: 12px !important; line-height: 14px !important; color: black !important; text-align: left !important; &quot; applecontenteditable=&quot;true&quot;&gt;&lt;br&gt;&lt;\/span&gt;&lt;\/span&gt;&lt;\/body&gt;&lt;\/html&gt;"
        # Attachments
        attachment0 = message.attachments.find{|attachment| attachment.filename == 'foo.txt'}
        attachment0.read.should == "fubar stands for fucked up beyond all recognition, but programmers use foobar. I'm not sure where foobar actually comes from."
      end
    end

    describe '#spam?' do
      it 'should return true if the response is spam' do
        message = service.transform(params('spam'))#[0]
        service.spam?(message).should == true
      end

      it 'should return false if the response is ham' do
        message = service.transform(params('valid'))#[0]
        service.spam?(message).should == false
      end
    end
  end  
end