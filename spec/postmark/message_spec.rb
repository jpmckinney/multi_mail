require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MultiMail::Message::Postmark do
  let :message do
    headers = {
      'X-Autoreply'  => true,
      'X-Precedence' => 'auto_reply',
      'X-Numeric'    => 42,
      'Delivered-To' => 'Autoresponder',
    }

    MultiMail::Message::Postmark.new do
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
    MultiMail::Message::Postmark.new do
      from    'foo@example.com'
      to      ['bar@example.com', 'baz@example.com']
      subject 'test'
      body    'hello'
    end
  end

  let :message_with_known_extension do
    MultiMail::Message::Postmark.new do
      from    'foo@example.com'
      to      'bar@example.com'
      subject 'test'
      body    'hello'
      add_file :filename => 'xxx.mov', :content => ''
    end
  end

  let :message_with_unknown_extension do
    MultiMail::Message::Postmark.new do
      from    'foo@example.com'
      to      'bar@example.com'
      subject 'test'
      body    'hello'
      add_file :filename => 'xxx.xxx', :content => ''
    end
  end

  let :message_without_extension do
    MultiMail::Message::Postmark.new do
      from    'foo@example.com'
      to      'bar@example.com'
      subject 'test'
      body    'hello'
      add_file :filename => 'xxx', :content => ''
    end
  end

  let :message_with_empty_headers do
    headers = {
      'X-Autoreply' => nil,
    }

    MultiMail::Message::Postmark.new do
      headers  headers
      from    'foo@example.com'
      to      'bar@example.com'
      reply_to nil
      subject  'test'
      body     'hello'
    end
  end

  let :message_without_html_body do
    MultiMail::Message::Postmark.new do
      from    'foo@example.com'
      to      'bar@example.com'
      subject 'test'
      body    'hello'
    end
  end

  let :message_without_text_body do
    MultiMail::Message::Postmark.new do
      from    'foo@example.com'
      to      'bar@example.com'
      subject 'test'
      body    '<p>hello</p>'
      content_type 'text/html; charset=UTF-8'
    end
  end

  let :empty_message do
    MultiMail::Message::Postmark.new
  end

  let :message_with_one_tag do
    MultiMail::Message::Postmark.new do
      tag 'foo'
    end
  end

  let :message_with_many_tags do
    MultiMail::Message::Postmark.new do
      tag 'foo'
      tag 'bar'
    end
  end

  describe '#postmark_headers' do
    it 'should return the headers' do
      headers = message.postmark_headers
      [ {'Name' => 'X-Autoreply', 'Value' => 'true'},
        {'Name' => 'X-Precedence', 'Value' => 'auto_reply'},
        {'Name' => 'X-Numeric', 'Value' => '42'},
        {'Name' => 'Delivered-To', 'Value' => 'Autoresponder'},
      ].each do |header|
        headers.should include(header)
      end
    end

    it 'should return empty X-* headers' do
      message_with_empty_headers.postmark_headers.should == [
        {'Name' => 'X-Autoreply', 'Value' => ''},
      ]
    end

    it 'should return an empty hash' do
      empty_message.postmark_headers.should == []
    end
  end

  describe '#postmark_attachments' do
    it 'should return the attachments' do
      message.postmark_attachments.should == [
        {
          'ContentType' => 'image/gif; filename=empty.gif',
          'Name' => 'empty.gif',
          'Content' => "R0lGODlhAQABAPABAP///wAAACH5BAEKAAAALAAAAAABAAEAAAICRAEAOw==\n",
          'ContentID' => 'empty.gif',
        },
        {
          'ContentType' => 'text/plain; filename=foo.txt',
          'Name' => 'foo.txt',
          'Content' => Base64.encode64('hello world'),
        },
      ]
    end

    it 'should return an attachment with an known extension' do
      message_with_known_extension.postmark_attachments.should == [
        {
          'ContentType' => 'video/quicktime; filename=xxx.mov',
          'Name' => 'xxx.mov',
          'Content' => '',
        },
      ]
    end

    it 'should return an attachment with an unknown extension' do
      message_with_unknown_extension.postmark_attachments.should == [
        {
          'ContentType' => 'text/plain',
          'Name' => 'xxx.xxx',
          'Content' => '',
        },
      ]
    end

    it 'should return an attachment without an extension' do
      message_without_extension.postmark_attachments.should == [
        {
          'ContentType' => 'text/plain',
          'Name' => 'xxx',
          'Content' => '',
        },
      ]
    end

    it 'should return an empty array' do
      empty_message.postmark_attachments.should == []
    end
  end

  describe '#to_postmark_hash' do
    it 'should return the message as Mandrill parameters' do
      hash = message.to_postmark_hash
      hash[:HtmlBody].should    == '<p>hello</p>'
      hash[:TextBody].should    == 'hello'
      hash[:Subject].should     == 'test'
      hash[:From].should        == '"John Doe" <foo@example.com>'
      hash[:To].should          == '"Jane Doe" <bar@example.com>, <baz@example.com>'
      hash[:Cc].should          == "cc@example.com"
      hash[:Bcc].should         == "bcc@example.com"
      hash[:ReplyTo].should     == "noreply@example.com"
      hash[:Attachments].should == [
        {
          'ContentType' => 'image/gif; filename=empty.gif',
          'Name' => 'empty.gif',
          'Content' => "R0lGODlhAQABAPABAP///wAAACH5BAEKAAAALAAAAAABAAEAAAICRAEAOw==\n",
          'ContentID' => 'empty.gif',
        },
        {
          'ContentType' => 'text/plain; filename=foo.txt',
          'Name' => 'foo.txt',
          'Content' => Base64.encode64('hello world'),
        },
      ]

      [ {'Name' => 'X-Autoreply', 'Value' => 'true'},
        {'Name' => 'X-Precedence', 'Value' => 'auto_reply'},
        {'Name' => 'X-Numeric', 'Value' => '42'},
        {'Name' => 'Delivered-To', 'Value' => 'Autoresponder'},
      ].each do |header|
        hash[:Headers].should include(header)
      end
    end

    it 'should return the recipients without names' do
      message_without_names.to_postmark_hash.should == {
        :TextBody => 'hello',
        :Subject  => 'test',
        :From     => 'foo@example.com',
        :To       => 'bar@example.com, baz@example.com',
      }
    end

    it 'should convert the message without a text body' do
      message_without_text_body.to_postmark_hash.should == {
        :HtmlBody => '<p>hello</p>',
        :Subject  => 'test',
        :From     => 'foo@example.com',
        :To       => 'bar@example.com',
      }
    end

    it 'should convert the message without an HTML body' do
      message_without_html_body.to_postmark_hash.should == {
        :TextBody => 'hello',
        :Subject  => 'test',
        :From     => 'foo@example.com',
        :To       => 'bar@example.com',
      }
    end

    it 'should convert an empty message' do
      empty_message.to_postmark_hash.should == {}
    end

    it 'should convert the message with one tag' do
      message_with_one_tag.to_postmark_hash.should == {
        :Tag => 'foo',
      }
    end

    it 'should convert the message with many tags' do
      message_with_many_tags.to_postmark_hash.should == {
        :Tag => 'foo',
      }
    end
  end
end
