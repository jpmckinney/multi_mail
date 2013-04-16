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
    #   to get fixtures to test the raw MIME HTTP POST format.
    ['parsed', '', nil].each do |http_post_format|
      context "with #{http_post_format.inspect} format" do
        let :http_post_format do
          http_post_format
        end

        let :actual_http_post_format do
          http_post_format.to_s.empty? ? 'parsed' : http_post_format
        end

        let :service do
          MultiMail::Receiver.new({
            :provider => :mailgun,
            :mailgun_api_key => 'foo',
            :http_post_format => http_post_format,
          })
        end

        def params(fixture)
          MultiMail::Receiver::Mailgun.parse(response("mailgun/#{actual_http_post_format}", fixture))
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
            message.date.should    == DateTime.parse('Mon, 15 Apr 2013 20:20:12 -04:00')
            message.from.should    == ['james@opennorth.ca']
            message.to.should      == ['foo+bar@multimail.mailgun.org']
            message.subject.should == 'Test'

            # Body
            message.multipart?.should            == true
            message.parts.size.should            == 4
            message.parts[0].content_type.should == 'text/plain'
            message.parts[0].body.should         == "bold text\n\n\n\nsome more bold text\n\n\n\nsome italic text\n\n> multiline\n> quoted\n> text\n\n\n--\nSignature block"
            message.parts[1].content_type.should == 'text/html; charset=UTF-8'
            message.parts[1].body.should         == %(<html><head></head><body style="word-wrap: break-word; -webkit-nbsp-mode: space; -webkit-line-break: after-white-space; "><b>bold text</b><div><br></div><div></div></body></html><html><body style="word-wrap: break-word; -webkit-nbsp-mode: space; -webkit-line-break: after-white-space; "><head></head><br><div></div><div><br></div><div><b>some more bold text</b></div><div><b><br></b></div><div><b></b></div></body></html><html><head></head><body style="word-wrap: break-word; -webkit-nbsp-mode: space; -webkit-line-break: after-white-space; "><br><div><b></b></div><div><b><span class="Apple-style-span" style="font-weight: normal; "><br></span></b></div><div><b><span class="Apple-style-span" style="font-weight: normal; "><i>some italic text</i></span></b></div><div><b><span class="Apple-style-span" style="font-weight: normal; "><br></span></b></div><div><blockquote type="cite">multiline</blockquote><blockquote type="cite">quoted</blockquote><blockquote type="cite">text</blockquote></div><div><br></div><div>--</div><div>Signature block</div></body></html>)

            # Attachments
            message.attachments[0].filename.should == 'foo.txt'
            message.attachments[0].read.should == "Lorem ipsum dolor sit amet, consectetur adipiscing elit.\n"
            message.attachments[1].filename.should == 'bar.txt'
            message.attachments[1].read.should == "Nam accumsan euismod eros et rhoncus.\n"

            # Extra Mailgun parameters
            # @note Due to a Mailgun bug, `stripped-text` contains "some italic
            #    text" but `stripped-html` doesn't. `stripped-signature` and
            #    `stripped-text` use CRLF line endings.
            if actual_http_post_format == 'raw'
              message['stripped-text'].should be_nil
              message['stripped-signature'].should be_nil
              message['stripped-html'].should be_nil
            else
              message['stripped-text'].value.should      == "bold text\r\n\r\n\r\n\r\nsome more bold text\r\n\r\n\r\n\r\nsome italic text"
              message['stripped-signature'].value.should == "--\r\nSignature block"
              message['stripped-html'].value.should      == '<html><head></head><body style="word-wrap: break-word; -webkit-nbsp-mode: space; -webkit-line-break: after-white-space; "><b>bold text</b><div><br></div><div></div></body><html><body style="word-wrap: break-word; -webkit-nbsp-mode: space; -webkit-line-break: after-white-space; "><br><div></div><div><br></div><div><b>some more bold text</b></div><div><b><br></b></div><div><b></b></div></body></html><html><head></head></html></html>'
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
end
