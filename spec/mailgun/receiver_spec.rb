require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'multi_mail/mailgun/receiver'

describe MultiMail::Receiver::Mailgun do
  describe '#initialize' do
    it 'should raise an error if :mailgun_api_key is missing' do
      expect{ MultiMail::Receiver.new :provider => :mailgun }.to raise_error(ArgumentError)
      expect{ MultiMail::Receiver.new :provider => :mailgun, :mailgun_api_key => nil }.to raise_error(ArgumentError)
    end
  end

  context 'after initialization' do
    context 'with invalid HTTP POST format' do
      let :service do
        MultiMail::Receiver.new({
          :provider => :mailgun,
          :mailgun_api_key => 'foo',
          :http_post_format => 'invalid',
        })
      end

      describe '#transform' do
        it 'should raise an error if :http_post_format is invalid' do
          expect{ service.transform({}) }.to raise_error(ArgumentError)
        end
      end
    end

    # @todo Need to run my own postbin to have a URL ending with "mime" in order
    # to get fixtures to test the raw MIME HTTP POST format.
    ['parsed', '', nil].each do |http_post_format|
      let :http_post_format do
        http_post_format
      end

      let :service do
        MultiMail::Receiver.new({
          :provider => :mailgun,
          :mailgun_api_key => 'foo',
          :http_post_format => http_post_format,
        })
      end

      def params(fixture)
        directory = http_post_format.to_s.empty? ? 'parsed' : http_post_format
        MultiMail::Receiver::Mailgun.parse(response("mailgun/#{directory}", fixture))
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
          message = service.transform(params('valid'))[0]

          # Headers
          message.date.should    == DateTime.parse('Mon, 14 Apr 2013 20:55:30 -04:00')
          message.from.should    == ['james@opennorth.ca']
          message.to.should      == ['foo+bar@multimail.mailgun.org']
          message.subject.should == 'Test'

          # Body
          message.multipart?.should            == true
          message.parts.size.should            == 4
          message.parts[0].content_type.should == 'text/plain'
          message.parts[0].body.should         == "bold text\n\n> multiline\n> quoted\n> text\n\n\n--\nSignature block\n"
          message.parts[1].content_type.should == 'text/html; charset=UTF-8'
          message.parts[1].body.should         == %(<html><head></head><body style="word-wrap: break-word; -webkit-nbsp-mode: space; -webkit-line-break: after-white-space; "><b>bold text</b><div><br></div><div><blockquote type="cite">multiline</blockquote><blockquote type="cite">quoted</blockquote><blockquote type="cite">text</blockquote></div><div><br></div><div>--</div><div>Signature block</div><div></div></body></html><html><body style="word-wrap: break-word; -webkit-nbsp-mode: space; -webkit-line-break: after-white-space; "><head></head><div></div></body></html><html><head></head><body style="word-wrap: break-word; -webkit-nbsp-mode: space; -webkit-line-break: after-white-space; "><div></div></body></html>)

          # Attachments
          message.attachments[0].filename.should == 'foo.txt'
          message.attachments[0].read.should == "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed fringilla consectetur rhoncus. Nunc mattis mattis urna quis molestie. Quisque ut mattis nisl. Donec neque felis, porta quis condimentum eu, pharetra non libero.\n"
          message.attachments[1].filename.should == 'bar.txt'
          message.attachments[1].read.should == "Nam accumsan euismod eros et rhoncus. Phasellus fermentum erat id lacus egestas vulputate. Pellentesque eu risus dui, id scelerisque neque. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus.\n"

          if http_post_format == 'parsed'
            # Extra Mailgun parameters
            message['stripped-text'].value.should      == 'bold text'
            message['stripped-signature'].value.should == "--\r\nSignature block"
            message['stripped-html'].value.should      == '<html><head></head><body style="word-wrap: break-word; -webkit-nbsp-mode: space; -webkit-line-break: after-white-space; "><b>bold text</b><div><br></div><div><br></div><div>--</div><div>Signature block</div><div></div></body><html><body style="word-wrap: break-word; -webkit-nbsp-mode: space; -webkit-line-break: after-white-space; "><div></div></body></html><html><head></head><body style="word-wrap: break-word; -webkit-nbsp-mode: space; -webkit-line-break: after-white-space; "><div></div></body></html></html>'
          end
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
end
