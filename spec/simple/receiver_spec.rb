require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'multi_mail/simple/receiver'

describe MultiMail::Receiver::Simple do
  let :service do
    MultiMail::Receiver.new({
      :provider => :simple,
      :secret => 'foo',
    })
  end

  def params(fixture)
    MultiMail::Receiver::Simple.parse(response('simple', fixture))
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
      message = service.transform(params('valid')['message'])[0]

      # Headers
      message.date.should    == DateTime.parse('Thu, 27 Dec 2012 15:25:37 -0500')
      message.from.should    == ['james@opennorth.ca']
      message.to.should      == ['foo+bar@govkit.org']
      message.subject.should == 'Test'

      # Body
      message.multipart?.should == true
      message.parts.size.should            == 2
      message.parts[0].content_type.should == 'text/plain; charset=us-ascii'
      message.parts[0].body.should         == "bold text\n\n\n> multiline\n> quoted\n> text\n\n--\nSignature block"
      message.parts[1].content_type.should == 'text/html; charset=us-ascii'
      message.parts[1].body.should         == %(<html><head></head><body style="word-wrap: break-word; -webkit-nbsp-mode: space; -webkit-line-break: after-white-space; "><div><b>bold text</b></div><div><br></div><div><blockquote type="cite"></blockquote></div><div><blockquote type="cite">multiline</blockquote></div><blockquote type="cite"><div>quoted</div><div>text</div></blockquote><br><div>--</div><div>Signature block</div></body></html>)
    end
  end
end
