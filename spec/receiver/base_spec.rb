require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MultiMail::Receiver::Base do
  let :klass do
    Class.new(MultiMail::Service) do
      include MultiMail::Receiver::Base

      def valid?(params)
        params['foo'] == 1
      end

      def transform(params)
        [Mail.new]
      end
    end
  end

  let :service do
    klass.new
  end

  describe '#process' do
    it 'should parse the request' do
      klass.should_receive(:parse).with('foo' => 1).once.and_return('foo' => 1)
      service.process('foo' => 1)
    end

    it 'should transform the request if the request is valid' do
      service.should_receive(:transform).with('foo' => 1).once
      service.process('foo' => 1)
    end

    it 'raise an error if the request is invalid' do
      expect{ service.process('foo' => 0) }.to raise_error(MultiMail::ForgedRequest)
    end
  end

  describe '#parse' do
    it 'should parse raw POST data' do
      klass.parse('foo=1&bar=1&bar=1').should == {'foo' => '1', 'bar' => ['1', '1']}
    end

    it 'should pass-through a hash' do
      klass.parse('foo' => 1).should == {'foo' => 1}
    end

    it 'should raise an error if the argument is invalid' do
      expect{ klass.parse(1) }.to raise_error(ArgumentError, "Can't handle Fixnum input")
    end
  end

  describe '#condense' do
    it "should condense a message's HTML parts to a single HTML part" do
      message = Mail.new(File.read(File.expand_path('../../fixtures/multipart.txt', __FILE__)))
      result = klass.condense(message.dup)

      result.parts.size.should == 4

      result.text_part.content_type.should == 'text/plain'
      result.html_part.content_type.should == 'text/html; charset=UTF-8'

      result.text_part.body.decoded.should == "bold text\n\n\n\nsome more bold text\n\n\n\nsome italic text\n\n> multiline\n> quoted\n> text\n\n\n--\nSignature block"
      result.html_part.body.decoded.should == "<html><head></head><body style=\"word-wrap: break-word; -webkit-nbsp-mode: space; -webkit-line-break: after-white-space; \"><b>bold text</b><div><br></div><div></div></body></html><html><body style=\"word-wrap: break-word; -webkit-nbsp-mode: space; -webkit-line-break: after-white-space; \"><head></head><br><div></div><div><br></div><div><b>some more bold text</b></div><div><b><br></b></div><div><b></b></div></body></html><html><head></head><body style=\"word-wrap: break-word; -webkit-nbsp-mode: space; -webkit-line-break: after-white-space; \"><br><div><b></b></div><div><b><span class=\"Apple-style-span\" style=\"font-weight: normal; \"><br></span></b></div><div><b><span class=\"Apple-style-span\" style=\"font-weight: normal; \"><i>some italic text</i></span></b></div><div><b><span class=\"Apple-style-span\" style=\"font-weight: normal; \"><br></span></b></div><div><blockquote type=\"cite\">multiline</blockquote><blockquote type=\"cite\">quoted</blockquote><blockquote type=\"cite\">text</blockquote></div><div><br></div><div>--</div><div>Signature block</div></body></html>"

      [ "Lorem ipsum dolor sit amet, consectetur adipiscing elit.\n",
        "Nam accumsan euismod eros et rhoncus.\n",
      ].each_with_index do |body,i|
        result.attachments[i].body.decoded.should == body
      end
    end
  end

  describe '#flatten' do
    it 'should flatten a hierarchy of message parts' do
      message = Mail.new(File.read(File.expand_path('../../fixtures/multipart.txt', __FILE__)))
      result = klass.flatten(Mail.new, message.parts.dup)

      result.parts.size.should == 6
      result.parts.none?(&:multipart?).should == true

      [ "bold text\n\n\n\nsome more bold text\n\n\n\nsome italic text\n\n> multiline\n> quoted\n> text\n\n\n--\nSignature block",
        "<html><head></head><body style=\"word-wrap: break-word; -webkit-nbsp-mode: space; -webkit-line-break: after-white-space; \"><b>bold text</b><div><br></div><div></div></body></html>",
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit.\n",
        "<html><body style=\"word-wrap: break-word; -webkit-nbsp-mode: space; -webkit-line-break: after-white-space; \"><head></head><br><div></div><div><br></div><div><b>some more bold text</b></div><div><b><br></b></div><div><b></b></div></body></html>",
        "Nam accumsan euismod eros et rhoncus.\n",
        "<html><head></head><body style=\"word-wrap: break-word; -webkit-nbsp-mode: space; -webkit-line-break: after-white-space; \"><br><div><b></b></div><div><b><span class=\"Apple-style-span\" style=\"font-weight: normal; \"><br></span></b></div><div><b><span class=\"Apple-style-span\" style=\"font-weight: normal; \"><i>some italic text</i></span></b></div><div><b><span class=\"Apple-style-span\" style=\"font-weight: normal; \"><br></span></b></div><div><blockquote type=\"cite\">multiline</blockquote><blockquote type=\"cite\">quoted</blockquote><blockquote type=\"cite\">text</blockquote></div><div><br></div><div>--</div><div>Signature block</div></body></html>",
      ].each_with_index do |body,i|
        result.parts[i].body.decoded.should == body
      end
    end
  end
end
