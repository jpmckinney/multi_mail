require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'multi_mail/mandrill/message'

describe MultiMail::Message::Mandrill do
  let :message do
    headers = {
      'X-Autoreply'  => true,
      'X-Precedence' => 'auto_reply',
      'X-Numeric'    => 42,
      'Delivered-To' => 'Autoresponder',
    }

    MultiMail::Message::Mandrill.new do
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
    MultiMail::Message::Mandrill.new do
      from    'foo@example.com'
      to      ['bar@example.com', 'baz@example.com']
      subject 'test'
      body    'hello'
    end
  end

  let :message_with_known_extension do
    MultiMail::Message::Mandrill.new do
      from    'foo@example.com'
      to      'bar@example.com'
      subject 'test'
      body    'hello'
      add_file :filename => 'xxx.mov', :content => ''
    end
  end

  let :message_with_unknown_extension do
    MultiMail::Message::Mandrill.new do
      from    'foo@example.com'
      to      'bar@example.com'
      subject 'test'
      body    'hello'
      add_file :filename => 'xxx.xxx', :content => ''
    end
  end

  let :message_without_extension do
    MultiMail::Message::Mandrill.new do
      from    'foo@example.com'
      to      'bar@example.com'
      subject 'test'
      body    'hello'
      add_file :filename => 'xxx', :content => ''
    end
  end

  let :message_with_empty_file do
    MultiMail::Message::Mandrill.new do
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

    MultiMail::Message::Mandrill.new do
      headers  headers
      from    'foo@example.com'
      to      'bar@example.com'
      reply_to nil
      subject  'test'
      body     'hello'
    end
  end

  let :message_without_html_body do
    MultiMail::Message::Mandrill.new do
      from    'foo@example.com'
      to      'bar@example.com'
      subject 'test'
      body    'hello'
    end
  end

  let :message_without_text_body do
    MultiMail::Message::Mandrill.new do
      from    'foo@example.com'
      to      'bar@example.com'
      subject 'test'
      body    '<p>hello</p>'
      content_type 'text/html; charset=UTF-8'
    end
  end

  let :empty_message do
    MultiMail::Message::Mandrill.new
  end

  describe '#mandrill_to' do
    it 'should return the recipients with names' do
      message.mandrill_to.should == [
        {
          'email' => 'bar@example.com',
          'name'  => 'Jane Doe',
        },
        {
          'email' => 'baz@example.com',
          'name'  => nil,
        },
      ]
    end

    it 'should return the recipients without names' do
      message_without_names.mandrill_to.should == [
        {
          'email' => 'bar@example.com',
          'name'  => nil,
        },
        {
          'email' => 'baz@example.com',
          'name'  => nil,
        },
      ]
    end

    it 'should return an empty array' do
      empty_message.mandrill_to.should == []
    end
  end

  describe '#mandrill_headers' do
    it 'should return only the Reply-To and X-* headers' do
      headers = message.mandrill_headers
      headers['Reply-To'].should == 'noreply@example.com'
      headers['X-Autoreply'].should == 'true'
      headers['X-Precedence'].should == 'auto_reply'
      headers['X-Numeric'].should == '42'
      headers.size.should == 4
    end

    it 'should return empty X-* headers' do
      headers = message_with_empty_headers.mandrill_headers
      headers['X-Autoreply'].should == ''
      headers.size.should == 1
    end

    it 'should return an empty hash' do
      empty_message.mandrill_headers.should == {}
    end
  end

  describe '#mandrill_attachments' do
    it 'should return the attachments' do
      message.mandrill_attachments.should == [
        {
          'type' => 'image/gif; filename=empty.gif',
          'name' => 'empty.gif',
          'content' => "R0lGODlhAQABAPABAP///wAAACH5BAEKAAAALAAAAAABAAEAAAICRAEAOw==\n",
        },
        {
          'type' => 'text/plain; filename=foo.txt',
          'name' => 'foo.txt',
          'content' => Base64.encode64('hello world'),
        },
      ]
    end

    it 'should return an attachment with an known extension' do
      message_with_known_extension.mandrill_attachments.should == [
        {
          'type' => 'video/quicktime; filename=xxx.mov',
          'name' => 'xxx.mov',
          'content' => '',
        },
      ]
    end

    it 'should return an attachment with an unknown extension' do
      message_with_unknown_extension.mandrill_attachments.should == [
        {
          'type' => 'text/plain',
          'name' => 'xxx.xxx',
          'content' => '',
        },
      ]
    end

    it 'should return an attachment without an extension' do
      message_without_extension.mandrill_attachments.should == [
        {
          'type' => 'text/plain',
          'name' => 'xxx',
          'content' => '',
        },
      ]
    end

    it 'should return an empty array if the attachment is blank' do
      message_with_empty_file.mandrill_attachments.should == []
    end

    it 'should return an empty array' do
      empty_message.mandrill_attachments.should == []
    end
  end

  describe '#to_mandrill_hash' do
    it 'should return the message as Mandrill parameters' do
      message.to_mandrill_hash.should == {
        'html'       => '<p>hello</p>',
        'text'       => 'hello',
        'subject'    => 'test',
        'from_email' => 'foo@example.com',
        'from_name'  => 'John Doe',
        'to'         => [
          {
          'email' => 'bar@example.com',
          'name'  => 'Jane Doe',
          },
          {
          'email' => 'baz@example.com',
          'name'  => nil,
          },
        ],
        'headers' => {
          'Reply-To'     => 'noreply@example.com',
          'X-Autoreply'  => 'true',
          'X-Precedence' => 'auto_reply',
          'X-Numeric'    => '42',
        },
        'attachments' => [
          {
            'type' => 'text/plain; filename=foo.txt',
            'name' => 'foo.txt',
            'content' => Base64.encode64('hello world'),
          },
        ],
        'images' => [
          {
            'type' => 'image/gif; filename=empty.gif',
            'name' => 'empty.gif',
            'content' => "R0lGODlhAQABAPABAP///wAAACH5BAEKAAAALAAAAAABAAEAAAICRAEAOw==\n",
          },
        ],
      }
    end

    it 'should convert the message without a text body' do
      message_without_text_body.to_mandrill_hash.should == {
        'html'       => '<p>hello</p>',
        'subject'    => 'test',
        'from_email' => 'foo@example.com',
        'to'         => [
          {
          'email' => 'bar@example.com',
          'name'  => nil,
          },
        ],
      }
    end

    it 'should convert the message without an HTML body' do
      message_without_html_body.to_mandrill_hash.should == {
        'text'       => 'hello',
        'subject'    => 'test',
        'from_email' => 'foo@example.com',
        'to'         => [
          {
          'email' => 'bar@example.com',
          'name'  => nil,
          },
        ],
      }
    end

    it 'should convert an empty message' do
      empty_message.to_mandrill_hash.should == {}
    end
  end
end
