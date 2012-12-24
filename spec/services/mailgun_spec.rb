require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'multi_mail/services/mailgun'

describe MultiMail::Mailgun do
  describe '#initialize' do
    it 'should raise an error if missing required arguments' do
      expect{ MultiMail.new :provider => :mailgun }.to raise_error(ArgumentError)
      expect{ MultiMail.new :provider => :mailgun, :mailgun_api_key => nil }.to raise_error(ArgumentError)
    end
  end

  context 'after initialization' do
    def params(fixture)
      MultiMail::Service.parse(response('mailgun', fixture))
    end

    before :all do
      @service = MultiMail.new :provider => :mailgun, :mailgun_api_key => credentials[:mailgun_api_key]
    end

    describe '#valid?' do
      it 'should return true if the response is valid' do
        @service.valid?(params('valid')).should == true
      end

      it 'should return false if the response is invalid' do
        @service.valid?(params('invalid')).should == false
      end

      it 'should raise an error if parameters are missing' do
        expect{ @service.valid?(params('missing')) }.to raise_error(KeyError)
      end
    end

    describe '#transform' do
      it 'should return a mail message' do
        message = @service.transform(params('valid'))

        # Headers
        message.date.should    == DateTime.parse('Mon, 24 Dec 2012 00:31:08 -0500')
        message.from.should    == ['james@opennorth.ca']
        message.to.should      == ['foo+bar@multimail.mailgun.org']
        message.subject.should == 'Test'

        # Body
        message.multipart?.should            == true
        message.parts.size.should            == 2
        message.parts[0].content_type.should == 'text/plain'
        message.parts[0].body.should         == "bold text\n\n> multiline\n> quoted\n> text\n\n\n--\nSignature block"
        message.parts[1].content_type.should == 'text/html; charset=UTF-8'
        message.parts[1].body.should         == '<html><head></head><body style="word-wrap: break-word; -webkit-nbsp-mode: space; -webkit-line-break: after-white-space; "><b>bold text</b><div><br></div><div><blockquote type="cite">multiline</blockquote><blockquote type="cite">quoted</blockquote><blockquote type="cite">text</blockquote></div><div><br></div><div>--</div><div>Signature block</div></body></html>'

        # Extra Mailgun parameters
        message['stripped-text'].value.should      == 'bold text'
        message['stripped-signature'].value.should == "--\r\nSignature block"
        message['stripped-html'].value.should      == '<html><head></head><body style="word-wrap: break-word; -webkit-nbsp-mode: space; -webkit-line-break: after-white-space; "><b>bold text</b><div><br></div><div><br></div><div>--</div><div>Signature block</div></body></html>'
      end
    end

    describe '#spam?' do
      it 'should return true if the response is spam' do
        message = @service.transform(params('spam'))
        @service.spam?(message).should == true
      end

      it 'should return false if the response is ham' do
        message = @service.transform(params('valid'))
        @service.spam?(message).should == false
      end
    end
  end
end
