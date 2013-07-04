require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'multi_mail/sendgrid/message'

describe MultiMail::Message::SendGrid do
  let :message do
    headers = {
      'X-Autoreply'  => true,
      'X-Precedence' => 'auto_reply',
      'X-Numeric'    => 42,
      'Delivered-To' => 'Autoresponder',
    }

    MultiMail::Message::SendGrid.new do
      date     Time.new(2000, 1, 1)
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
    MultiMail::Message::SendGrid.new do
      from    'foo@example.com'
      to      ['bar@example.com', 'baz@example.com']
      subject 'test'
      body    'hello'
    end
  end

  let :message_with_known_extension do
    MultiMail::Message::SendGrid.new do
      from    'foo@example.com'
      to      'bar@example.com'
      subject 'test'
      body    'hello'
      add_file :filename => 'xxx.mov', :content => ''
    end
  end

  let :message_with_unknown_extension do
    MultiMail::Message::SendGrid.new do
      from    'foo@example.com'
      to      'bar@example.com'
      subject 'test'
      body    'hello'
      add_file :filename => 'xxx.xxx', :content => ''
    end
  end

  let :message_without_extension do
    MultiMail::Message::SendGrid.new do
      from    'foo@example.com'
      to      'bar@example.com'
      subject 'test'
      body    'hello'
      add_file :filename => 'xxx', :content => ''
    end
  end

  let :message_with_empty_file do
    MultiMail::Message::SendGrid.new do
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

    MultiMail::Message::SendGrid.new do
      headers  headers
      from    'foo@example.com'
      to      'bar@example.com'
      reply_to nil
      subject  'test'
      body     'hello'
    end
  end

  let :message_without_html_body do
    MultiMail::Message::SendGrid.new do
      from    'foo@example.com'
      to      'bar@example.com'
      subject 'test'
      body    'hello'
    end
  end

  let :message_without_text_body do
    MultiMail::Message::SendGrid.new do
      from    'foo@example.com'
      to      'bar@example.com'
      subject 'test'
      body    '<p>hello</p>'
      content_type 'text/html; charset=UTF-8'
    end
  end

  let :empty_message do
    MultiMail::Message::SendGrid.new
  end

  describe '#sendgrid_files' do
    it 'should return the attachments' do
      files = message.sendgrid_files
      files[0].content_type.should == 'image/gif; filename=empty.gif'
      files[0].original_filename.should == 'empty.gif'
      files[0].read.should == File.open(empty_gif_path, 'r:binary'){|f| f.read}
      files[1].content_type.should == 'text/plain; filename=foo.txt'
      files[1].original_filename.should == 'foo.txt'
      files[1].read.should == 'hello world'
      files.size.should == 2
    end

    it 'should return an attachment with an known extension' do
      files = message_with_known_extension.sendgrid_files
      files[0].content_type.should == 'video/quicktime; filename=xxx.mov'
      files[0].original_filename.should == 'xxx.mov'
      files[0].read.should == ''
      files.size.should == 1
    end

    it 'should return an attachment with an unknown extension' do
      files = message_with_unknown_extension.sendgrid_files
      files[0].content_type.should == 'text/plain'
      files[0].original_filename.should == 'xxx.xxx'
      files[0].read.should == ''
      files.size.should == 1
    end

    it 'should return an attachment without an extension' do
      files = message_without_extension.sendgrid_files
      files[0].content_type.should == 'text/plain'
      files[0].original_filename.should == 'xxx'
      files[0].read.should == ''
      files.size.should == 1
    end

    it 'should return an empty array if the attachment is blank' do
      message_with_empty_file.sendgrid_files.should == []
    end

    it 'should return an empty array' do
      empty_message.sendgrid_files.should == []
    end
  end

  describe '#sendgrid_content' do
    it 'should return the content IDs' do
      content = message.sendgrid_content
      content.each do |cid|
        cid.should match(/\A\S+@\S+\z/)
      end
      content.size.should == 2
    end

    it 'should return an empty array if the attachment is blank' do
      message_with_empty_file.sendgrid_content.should == []
    end

    it 'should return an empty array' do
      empty_message.sendgrid_content.should == []
    end
  end

  describe '#sendgrid_headers' do
    it 'should return the headers' do
      headers = message.sendgrid_headers
      headers['Cc'].should           == 'cc@example.com'
      headers['X-Autoreply'].should  == 'true'
      headers['X-Precedence'].should == 'auto_reply'
      headers['X-Numeric'].should    == '42'
      headers['Delivered-To'].should == 'Autoresponder'

      headers['Content-Type'].should match(%r{\Amultipart/alternative; boundary=--==_mimepart_[0-9a-f_]+\z})

      headers.size.should == 6
    end

    it 'should return empty X-* headers' do
      headers = message_with_empty_headers.sendgrid_headers
      headers['X-Autoreply'].should == ''
      headers.size.should == 1
    end

    it 'should return an empty hash' do
      empty_message.sendgrid_headers.should == {}
    end
  end

  describe '#to_sendgrid_hash' do
    it 'should return the message as SendGrid parameters' do
      hash = message.to_sendgrid_hash

      hash['to'].should       == ['bar@example.com', 'baz@example.com']
      hash['toname'].should   == ['Jane Doe', nil]
      hash['subject'].should  == 'test'
      hash['text'].should     == 'hello'
      hash['html'].should     == '<p>hello</p>'
      hash['from'].should     == 'foo@example.com'
      hash['bcc'].should      == ['bcc@example.com']
      hash['fromname'].should == 'John Doe'
      hash['replyto'].should  == 'noreply@example.com'

      hash['headers'].should match(%r{\A\{"Cc":"cc@example.com","Content-Type":"multipart/alternative; boundary=--==_mimepart_[0-9a-f_]+","X-Autoreply":"true","X-Precedence":"auto_reply","X-Numeric":"42","Delivered-To":"Autoresponder"\}\z})

      hash['content'].each do |cid|
        cid.should match(/\A\S+@\S+\z/)
      end
      hash['content'].size.should == 2

      Time.parse(hash['date']).should be_within(1).of(Time.new(2000, 1, 1))

      hash['files'][0].content_type.should == 'image/gif; filename=empty.gif'
      hash['files'][0].original_filename.should == 'empty.gif'
      hash['files'][0].read.should == File.open(empty_gif_path, 'r:binary'){|f| f.read}
      hash['files'][1].content_type.should == 'text/plain; filename=foo.txt'
      hash['files'][1].original_filename.should == 'foo.txt'
      hash['files'][1].read.should == 'hello world'
      hash['files'].size.should == 2

      hash.size.should == 13
    end

    it 'should convert the message without a text body' do
      message_without_text_body.to_sendgrid_hash.should == {
        'to'      => ['bar@example.com'],
        'subject' => 'test',
        'html'    => '<p>hello</p>',
        'from'    => 'foo@example.com',
        'headers' => %({"Content-Type":"text/html; charset=UTF-8"}),
      }
    end

    it 'should convert the message without an HTML body' do
      message_without_html_body.to_sendgrid_hash.should == {
        'to'      => ['bar@example.com'],
        'subject' => 'test',
        'text'    => 'hello',
        'from'    => 'foo@example.com',
      }
    end

    it 'should convert an empty message' do
      empty_message.to_sendgrid_hash.should == {}
    end
  end
end
