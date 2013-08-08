require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MultiMail::Message::Base do
  let :text_message do
    MultiMail::Message::Base.new do
      from    'foo@example.com'
      to      'bar@example.com'
      subject 'test'
      body    'hello'
    end
  end

  let :html_message do
    MultiMail::Message::Base.new do
      from    'foo@example.com'
      to      'bar@example.com'
      subject 'test'
      body    '<p>hello</p>'
      content_type 'text/html; charset=UTF-8'
    end
  end

  let :html_and_text_message do
    MultiMail::Message::Base.new do
      from    'foo@example.com'
      to      'bar@example.com'
      subject 'test'

      text_part do
        body 'hello'
      end

      html_part do
        content_type 'text/html; charset=UTF-8'
        body '<p>hello</p>'
      end
    end
  end

  describe '#html?' do
    it 'should return false if the message is text only' do
      text_message.html?.should == false
    end

    it 'should return true if the message is HTML only' do
      html_message.html?.should == true
    end

    it 'should return false if the message has both HTML and text parts' do
      html_and_text_message.html?.should == false
    end
  end

  describe '#body_html' do
    it 'should not return the body if the message is text only' do
      text_message.body_html.should be_nil
    end

    it 'should return the body if the message is HTML only' do
      html_message.body_html.should == '<p>hello</p>'
    end

    it 'should return the body if the message has both HTML and text parts' do
      html_and_text_message.body_html.should == '<p>hello</p>'
    end
  end

  describe '#body_text' do
    it 'should return the body if the message is text only' do
      text_message.body_text.should == 'hello'
    end

    it 'should return not the body if the message is HTML only' do
      html_message.body_text.should be_nil
    end

    it 'should return the body if the message has both HTML and text parts' do
      html_and_text_message.body_text.should == 'hello'
    end
  end

  let :many_tags do
    MultiMail::Message::Base.new do
      tag 'foo'
      tag 'bar'
    end
  end

  let :one_tag do
    MultiMail::Message::Base.new do
      tag 'foo'
    end
  end

  let :no_tag do
    MultiMail::Message::Base.new do
    end
  end

  describe '#tags' do
    it 'should return a multi-value array if many tags are set' do
      many_tags.tags.should == ['foo', 'bar']
    end

    it 'should return a single value array if one tag is set' do
      one_tag.tags.should == ['foo']
    end

    it 'should return an empty array if no tags are set' do
      no_tag.tags.should == []
    end
  end
end
