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

=begin		describe '#valid?' do
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
=end
    describe '#transform' do
      it 'should return a mail message' do
 #       messages = service.transform(params('valid'))
 #       messages.size.should == 1
 #       message = messages[0]
  			message = service.transform(params('valid'))
        puts message.headers
        # Headers
        message.date.should    == DateTime.parse('Tue, 14 May 2013 15:30:36 -0400')
        message.from.should    == ['alexi@opennorth.ca']
        message.to.should      == ['4354473e2e6ab001fa836f627a54004e@inbound.postmarkapp.com']
        message.subject.should == 'Test'

        # Body
        message.multipart?.should            == true
        message.parts.size.should            == 4
        message.parts[0].content_type.should == 'text/plain'
        message.parts[0].body.decoded.should == "This message is a test"

        # Attachments
        attachment0 = message.attachments.find{|attachment| attachment.filename == 'foo.txt'}
        attachment0.read.should == "fubar stands for fucked up beyond all recognition, but programmers use foobar. I'm not sure where foobar actually comes from."
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