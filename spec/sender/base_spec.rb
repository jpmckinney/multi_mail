require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

# @see https://github.com/mikel/mail/blob/master/lib/mail/network/delivery_methods/test_mailer.rb
class TestMailer
  include MultiMail::Sender::Base

  def initialize(options = {})
  end

  def self.deliveries
    @deliveries ||= []
  end

  def deliver!(mail)
    self.class.deliveries << mail
  end
end

describe MultiMail::Sender::Base do
  let :klass do
    Class.new do
      include MultiMail::Sender::Base
    end
  end

  let :message do
    Mail.new do
      from    'foo@example.com'
      to      'bar@example.com'
      subject 'test'
      body    'hello'
    end
  end

  let :html_message do
    Mail.new do
      from    'foo@example.com'
      to      'bar@example.com'
      subject 'test'
      body    '<p>hello</p>'
      content_type 'text/html; charset=UTF-8'
    end
  end

  let :html_and_text_message do
    Mail.new do
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

  describe '#deliver' do
    it 'should deliver a message' do
      TestMailer.deliveries.clear

      message.delivery_method TestMailer
      message.deliver

      TestMailer.deliveries.size.should == 1
      TestMailer.deliveries.first.should == message
    end
  end

  describe '#html?' do
    it 'should return false if the message is text only' do
      klass.html?(message).should == false
    end

    it 'should return true if the message is HTML only' do
      klass.html?(html_message).should == true
    end

    it 'should return false if the message has both HTML and text parts' do
      klass.html?(html_and_text_message).should == false
    end
  end

  describe '#html_part' do
    it 'should not return the body if the message is text only' do
      klass.html_part(message).should be_nil
    end

    it 'should return the body if the message is HTML only' do
      klass.html_part(html_message).should == '<p>hello</p>'
    end

    it 'should return the body if the message has both HTML and text parts' do
      klass.html_part(html_and_text_message).should == '<p>hello</p>'
    end
  end

  describe '#text_part' do
    it 'should return the body if the message is text only' do
      klass.text_part(message).should == 'hello'
    end

    it 'should return not the body if the message is HTML only' do
      klass.text_part(html_message).should be_nil
    end

    it 'should return the body if the message has both HTML and text parts' do
      klass.text_part(html_and_text_message).should == 'hello'
    end
  end
end
