require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MultiMail::Message::Mailgun do
  let :message do
    headers = {
      'X-Autoreply'  => true,
      'X-Precedence' => 'auto_reply',
      'X-Numeric'    => 42,
      'Delivered-To' => 'Autoresponder',
    }

    MultiMail::Message::Mailgun.new do
      date     Time.at(946702800)
      headers  headers
      from     %("John Doe" <foo@example.com>)
      to       [%("Jane Doe" <bar@example.com>), '<baz@example.com>']
      cc       'cc@example.com'
      bcc      'bcc@example.com'
      reply_to 'noreply@example.com'
      subject  'test'

      text_part do
        body 'hello'
      end

      html_part do
        content_type 'text/html; charset=UTF-8'
        body '<p>hello</p>'
      end

      add_file  empty_gif_path
      add_file  :filename => 'foo.txt', :content => 'hello world'
    end
  end

  let :message_without_names do
    MultiMail::Message::Mailgun.new do
      from    'foo@example.com'
      to      ['bar@example.com', 'baz@example.com']
      subject 'test'
      body    'hello'
    end
  end

  let :message_with_known_extension do
    MultiMail::Message::Mailgun.new do
      from    'foo@example.com'
      to      'bar@example.com'
      subject 'test'
      body    'hello'
      add_file :filename => 'xxx.mov', :content => ''
    end
  end

  let :message_with_unknown_extension do
    MultiMail::Message::Mailgun.new do
      from    'foo@example.com'
      to      'bar@example.com'
      subject 'test'
      body    'hello'
      add_file :filename => 'xxx.xxx', :content => ''
    end
  end

  let :message_without_extension do
    MultiMail::Message::Mailgun.new do
      from    'foo@example.com'
      to      'bar@example.com'
      subject 'test'
      body    'hello'
      add_file :filename => 'xxx', :content => ''
    end
  end

  let :message_with_empty_file do
    MultiMail::Message::Mailgun.new do
      from    'foo@example.com'
      to      'bar@example.com'
      subject 'test'
      body    'hello'
      add_file :filename => '', :content => ''
    end
  end

  let :message_with_empty_headers do
    headers = {
      'X-Autoreply' => nil,
    }

    MultiMail::Message::Mailgun.new do
      headers  headers
      from    'foo@example.com'
      to      'bar@example.com'
      reply_to nil
      subject  'test'
      body     'hello'
    end
  end

  let :message_without_html_body do
    MultiMail::Message::Mailgun.new do
      from    'foo@example.com'
      to      'bar@example.com'
      subject 'test'
      body    'hello'
    end
  end

  let :message_without_text_body do
    MultiMail::Message::Mailgun.new do
      from    'foo@example.com'
      to      'bar@example.com'
      subject 'test'
      body    '<p>hello</p>'
      content_type 'text/html; charset=UTF-8'
    end
  end

  let :empty_message do
    MultiMail::Message::Mailgun.new
  end

  let :message_with_one_tag do
    MultiMail::Message::Mailgun.new do
      tag 'foo'
    end
  end

  let :message_with_many_tags do
    MultiMail::Message::Mailgun.new do
      tag 'foo'
      tag 'bar'
    end
  end

  describe '#mailgun_attachments' do
    it 'should return the attachments' do
      attachments = message.mailgun_attachments
      attachments['inline'][0].content_type.should == 'image/gif; filename=empty.gif'
      attachments['inline'][0].original_filename.should == 'empty.gif'
      attachments['inline'][0].read.should == File.open(empty_gif_path, 'r:binary'){|f| f.read}
      attachments['inline'].size.should == 1
      attachments['attachment'][0].content_type.should == 'text/plain; filename=foo.txt'
      attachments['attachment'][0].original_filename.should == 'foo.txt'
      attachments['attachment'][0].read.should == 'hello world'
      attachments['attachment'].size.should == 1
    end

    it 'should return an attachment with an known extension' do
      attachments = message_with_known_extension.mailgun_attachments['attachment']
      attachments[0].content_type.should == 'video/quicktime; filename=xxx.mov'
      attachments[0].original_filename.should == 'xxx.mov'
      attachments[0].read.should == ''
      attachments.size.should == 1
    end

    it 'should return an attachment with an unknown extension' do
      attachments = message_with_unknown_extension.mailgun_attachments['attachment']
      attachments[0].content_type.should == 'text/plain'
      attachments[0].original_filename.should == 'xxx.xxx'
      attachments[0].read.should == ''
      attachments.size.should == 1
    end

    it 'should return an attachment without an extension' do
      attachments = message_without_extension.mailgun_attachments['attachment']
      attachments[0].content_type.should == 'text/plain'
      attachments[0].original_filename.should == 'xxx'
      attachments[0].read.should == ''
      attachments.size.should == 1
    end

    it 'should return an empty array if the attachment is blank' do
      message_with_empty_file.mailgun_attachments.should == {}
    end

    it 'should return an empty array' do
      empty_message.mailgun_attachments.should == {}
    end
  end

  describe '#mailgun_headers' do
    it 'should return the headers' do
      headers = message.mailgun_headers
      headers['h:Reply-To'].should     == ['noreply@example.com']
      headers['h:X-Autoreply'].should  == ['true']
      headers['h:X-Precedence'].should == ['auto_reply']
      headers['h:X-Numeric'].should    == ['42']
      headers['h:Delivered-To'].should == ['Autoresponder']

      Time.parse(headers['h:Date'][0]).should be_within(1).of(Time.at(946702800))
      headers['h:Content-Type'][0].should match(%r{\Amultipart/alternative; boundary=--==_mimepart_[0-9a-f_]+\z})

      headers.size.should == 7
    end

    it 'should return empty X-* headers' do
      headers = message_with_empty_headers.mailgun_headers
      headers.should == {'h:X-Autoreply' => ['']}
    end

    it 'should return an empty hash' do
      empty_message.mailgun_headers.should == {}
    end
  end

  describe '#to_mailgun_hash' do
    it 'should return the message as Mailgun parameters' do
      hash = message.to_mailgun_hash

      hash[:from].should         == [%("John Doe" <foo@example.com>)]
      hash[:to].should           == [%("Jane Doe" <bar@example.com>), '<baz@example.com>']
      hash[:cc].should           == ['cc@example.com']
      hash[:bcc].should          == ['bcc@example.com']
      hash[:subject].should      == ['test']
      hash[:text].should         == ['hello']
      hash[:html].should         == ['<p>hello</p>']
      hash[:'h:Reply-To'].should == ['noreply@example.com']

      Time.parse(hash[:'h:Date'][0]).should be_within(1).of(Time.at(946702800))
      hash[:'h:Content-Type'][0].should match(%r{\Amultipart/alternative; boundary=--==_mimepart_[0-9a-f_]+\z})

      hash[:'h:X-Autoreply'].should  == ['true']
      hash[:'h:X-Precedence'].should == ['auto_reply']
      hash[:'h:X-Numeric'].should    == ['42']
      hash[:'h:Delivered-To'].should == ['Autoresponder']

      hash[:inline][0].content_type.should == 'image/gif; filename=empty.gif'
      hash[:inline][0].original_filename.should == 'empty.gif'
      hash[:inline][0].read.should == File.open(empty_gif_path, 'r:binary'){|f| f.read}
      hash[:inline].size.should == 1
      hash[:attachment][0].content_type.should == 'text/plain; filename=foo.txt'
      hash[:attachment][0].original_filename.should == 'foo.txt'
      hash[:attachment][0].read.should == 'hello world'
      hash[:attachment].size.should == 1

      hash.size.should == 16
    end

    it 'should return the recipients without names' do
      hash = message_without_names.to_mailgun_hash
      hash[:from].should == ['foo@example.com']
      hash[:to].should == ['bar@example.com', 'baz@example.com']
    end

    it 'should convert the message without a text body' do
      message_without_text_body.to_mailgun_hash.should == {
        :from             => ['foo@example.com'],
        :to               => ['bar@example.com'],
        :subject          => ['test'],
        :html             => ['<p>hello</p>'],
        :'h:Content-Type' => ['text/html; charset=UTF-8'],
      }
    end

    it 'should convert the message without an HTML body' do
      message_without_html_body.to_mailgun_hash.should == {
        :from    => ['foo@example.com'],
        :to      => ['bar@example.com'],
        :subject => ['test'],
        :text    => ['hello'],
      }
    end

    it 'should convert an empty message' do
      empty_message.to_mailgun_hash.should == {}
    end

    it 'should convert the message with one tag' do
      message_with_one_tag.to_mailgun_hash.should == {
        :'o:tag' => ['foo'],
      }
    end

    it 'should convert the message with many tags' do
      message_with_many_tags.to_mailgun_hash.should == {
        :'o:tag' => ['foo', 'bar'],
      }
    end
  end
end
