require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'multi_mail/mailgun/receiver'

describe MultiMail::Receiver::Mailgun do
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

  context 'without optional arguments' do
    let :service do
      MultiMail::Receiver.new(:provider => :mailgun)
    end

    def params(fixture)
      MultiMail::Receiver::Mailgun.parse(response('mailgun/parsed', fixture))
    end

    describe '#valid?' do
      it 'should return true if the response is valid' do
        service.valid?(params('valid')).should == true
      end

      it 'should return true if the response is invalid' do
        service.valid?(params('invalid')).should == true
      end

      it 'should return true if parameters are missing' do
        service.valid?(params('missing')).should == true
      end
    end
  end

  [false, true].each do |action_dispatch|
    let :action_dispatch do
      action_dispatch
    end

    ['parsed', 'raw', '', nil].each do |http_post_format|
      context "with #{http_post_format.inspect} format and #{action_dispatch ? 'ActionDispatch' : 'Rack'}" do
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
          MultiMail::Receiver::Mailgun.parse(response("mailgun/#{actual_http_post_format}", fixture, action_dispatch))
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
            messages = service.transform(params('valid'))
            messages.size.should == 1
            message = messages[0]

            # Headers
            message.date.should    == DateTime.parse('Mon, 15 Apr 2013 20:20:12 -04:00')
            message.from.should    == ['james@opennorth.ca']
            message.to.should      == ['foo+bar@multimail.mailgun.org']
            message.subject.should == 'Test'

            # Body
            message.multipart?.should == true
            message.parts.size.should == 4
            text_part = message.parts.find{|part| part.content_type == 'text/plain'}
            html_part = message.parts.find{|part| part.content_type == 'text/html; charset=UTF-8'}
            text_part.body.decoded.should == "bold text\n\n\n\nsome more bold text\n\n\n\nsome italic text\n\n> multiline\n> quoted\n> text\n\n\n--\nSignature block"
            html_part.body.decoded.should == %(<html><head></head><body style="word-wrap: break-word; -webkit-nbsp-mode: space; -webkit-line-break: after-white-space; "><b>bold text</b><div><br></div><div></div></body></html><html><body style="word-wrap: break-word; -webkit-nbsp-mode: space; -webkit-line-break: after-white-space; "><head></head><br><div></div><div><br></div><div><b>some more bold text</b></div><div><b><br></b></div><div><b></b></div></body></html><html><head></head><body style="word-wrap: break-word; -webkit-nbsp-mode: space; -webkit-line-break: after-white-space; "><br><div><b></b></div><div><b><span class="Apple-style-span" style="font-weight: normal; "><br></span></b></div><div><b><span class="Apple-style-span" style="font-weight: normal; "><i>some italic text</i></span></b></div><div><b><span class="Apple-style-span" style="font-weight: normal; "><br></span></b></div><div><blockquote type="cite">multiline</blockquote><blockquote type="cite">quoted</blockquote><blockquote type="cite">text</blockquote></div><div><br></div><div>--</div><div>Signature block</div></body></html>)

            # Attachments
            attachment0 = message.attachments.find{|attachment| attachment.filename == 'foo.txt'}
            attachment1 = message.attachments.find{|attachment| attachment.filename == 'bar.txt'}
            attachment0.read.should == "Lorem ipsum dolor sit amet, consectetur adipiscing elit.\n"
            attachment1.read.should == "Nam accumsan euismod eros et rhoncus.\n"

            # Extra Mailgun parameters
            # @note Due to a Mailgun bug, `stripped-text` contains "some italic
            #    text" but `stripped-html` doesn't. `stripped-signature` and
            #    `stripped-text` use CRLF line endings.
            if actual_http_post_format == 'raw'
              message.stripped_text.should be_nil
              message.stripped_signature.should be_nil
              message.stripped_html.should be_nil
            else
              message.stripped_text.should      == "bold text\r\n\r\n\r\n\r\nsome more bold text\r\n\r\n\r\n\r\nsome italic text"
              message.stripped_signature.should == "--\r\nSignature block"
              message.stripped_html.should      == '<html><head></head><body style="word-wrap: break-word; -webkit-nbsp-mode: space; -webkit-line-break: after-white-space; "><b>bold text</b><div><br></div><div></div></body><html><body style="word-wrap: break-word; -webkit-nbsp-mode: space; -webkit-line-break: after-white-space; "><br><div></div><div><br></div><div><b>some more bold text</b></div><div><b><br></b></div><div><b></b></div></body></html><html><head></head></html></html>'
            end
          end
        end

        describe '#spam?' do
          it 'should return true if the response is spam' do
            # The raw MIME HTTP POST format doesn't perform spam filtering.
            message = service.transform(params('spam'))[0]
            service.spam?(message).should == (actual_http_post_format != 'raw')
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
