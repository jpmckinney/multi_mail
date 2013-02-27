require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'multi_mail/mandrill/receiver'

describe MultiMail::Receiver::Mandrill do
  describe '#initialize' do
    it 'should raise an error if :mandrill_api_key is missing' do
      expect{ MultiMail::Receiver.new :provider => :mandrill }.to raise_error(ArgumentError)
      expect{ MultiMail::Receiver.new :provider => :mandrill, :mandrill_api_key => nil }.to raise_error(ArgumentError)
    end
  end

  context 'after initialization' do
    def params(fixture)
      MultiMail::Receiver::Mandrill.parse(response('mandrill', fixture))
    end

    before :all do
      @service = MultiMail::Receiver.new({
        :provider => :mandrill,
        :mandrill_api_key => 'foo',
      })
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
        message = @service.transform(params('valid'))[0]

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

        # Extra Mandrill parameters
        message['email'].value.should == 'foo+bar@govkit.org'
        message['tags'].should be_nil
        message['sender'].should be_nil
      end
    end
  end
end
