require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'multi_mail/mailgun/sender'

describe MultiMail::Sender::Mailgun do
  let :message do
    Mail.new do
      date    Time.new(2000, 1, 1)
      from    'foo@example.com'
      to      'bar@example.com'
      subject 'test'
      body    'hello'
    end
  end

  let :empty_message do
    Mail.new do
      date    Time.new(2000, 1, 1)
    end
  end

  describe '#initialize' do
    it 'should raise an error if :api_key is missing' do
      expect{
        message.delivery_method MultiMail::Sender::Mailgun, :domain => 'xxx'
        message.deliver # request not sent
      }.to raise_error(ArgumentError, "Missing required arguments: :api_key")
    end

    it 'should raise an error if :domain is missing' do
      expect{
        message.delivery_method MultiMail::Sender::Mailgun, :api_key => 'xxx'
        message.deliver # request not sent
      }.to raise_error(ArgumentError, "Missing required arguments: :domain")
    end

    it 'should raise an error if :api_key is nil' do
      expect{
        message.delivery_method MultiMail::Sender::Mailgun, :api_key => nil, :domain => 'xxx'
        message.deliver # request not sent
      }.to raise_error(ArgumentError, "Missing required arguments: :api_key")
    end

    it 'should raise an error if :domain is nil' do
      expect{
        message.delivery_method MultiMail::Sender::Mailgun, :api_key => 'xxx', :domain => nil
        message.deliver # request not sent
      }.to raise_error(ArgumentError, "Missing required arguments: :domain")
    end

    it 'should raise an error if :domain or :api_key are invalid' do
      expect{
        message.delivery_method MultiMail::Sender::Mailgun, :api_key => 'xxx', :domain => 'xxx'
        message.deliver
      }.to raise_error(MultiMail::InvalidAPIKey)
    end

    it 'should assign custom settings' do
      sender = MultiMail::Sender::Mailgun.new(:api_key => 'xxx', :domain => 'xxx')

      sender.api_key.should == 'xxx'
      sender.domain.should  == 'xxx'
    end
  end

  describe '#deliver' do
    before :all do
      Mail.defaults do
        delivery_method MultiMail::Sender::Mailgun, :api_key => ENV['MAILGUN_API_KEY'], :domain => 'multimail.mailgun.org', 'o:testmode' => true
      end
    end

    it 'should send a message' do
      message.deliver.should == message
    end
  end

  describe '#deliver!' do
    before :all do
      Mail.defaults do
        delivery_method MultiMail::Sender::Mailgun, :api_key => ENV['MAILGUN_API_KEY'], :domain => 'multimail.mailgun.org', 'o:testmode' => true, :return_response => true
      end
    end

    it 'should send a message' do
      result = message.deliver!
      result.size.should == 1

      result['message'].should == 'success'
    end

    it 'should not send an empty message' do
      expect{empty_message.deliver!}.to raise_error(MultiMail::InvalidMessage)
    end
  end
end
