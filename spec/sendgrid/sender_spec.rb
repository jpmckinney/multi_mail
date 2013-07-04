require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'multi_mail/sendgrid/sender'

describe MultiMail::Sender::SendGrid do
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
    it 'should raise an error if :api_user is missing' do
      expect{
        message.delivery_method MultiMail::Sender::SendGrid, :api_key => 'xxx'
        message.deliver # request not sent
      }.to raise_error(ArgumentError, "Missing required arguments: api_user")
    end

    it 'should raise an error if :api_key is missing' do
      expect{
        message.delivery_method MultiMail::Sender::SendGrid, :api_user => 'xxx'
        message.deliver # request not sent
      }.to raise_error(ArgumentError, "Missing required arguments: api_key")
    end

    it 'should raise an error if :api_user is nil' do
      expect{
        message.delivery_method MultiMail::Sender::SendGrid, :api_user => nil, :api_key => 'xxx'
        message.deliver # request not sent
      }.to raise_error(ArgumentError, "Missing required arguments: api_user")
    end

    it 'should raise an error if :api_key is nil' do
      expect{
        message.delivery_method MultiMail::Sender::SendGrid, :api_user => 'xxx', :api_key => nil
        message.deliver # request not sent
      }.to raise_error(ArgumentError, "Missing required arguments: api_key")
    end

    it 'should raise an error if :api_user or :api_key are invalid' do
      expect{
        message.delivery_method MultiMail::Sender::SendGrid, :api_user => 'xxx', :api_key => 'xxx'
        message.deliver
      }.to raise_error(MultiMail::InvalidAPIKey)
    end

    it 'should transform x-smtpapi to JSON if it is not JSON' do
      sender = MultiMail::Sender::SendGrid.new(:api_user => '', :api_key => '', 'x-smtpapi' => {:foo => 'bar'})
      sender.settings[:'x-smtpapi'].should == '{"foo":"bar"}'
    end

    it 'should not transform x-smtpapi to JSON if it is JSON' do
      sender = MultiMail::Sender::SendGrid.new(:api_user => '', :api_key => '', 'x-smtpapi' => '{"foo":"bar"}')
      sender.settings[:'x-smtpapi'].should == '{"foo":"bar"}'
    end
  end

  describe '#deliver' do
    before :all do
      Mail.defaults do
        delivery_method MultiMail::Sender::SendGrid, :api_user => ENV['SENDGRID_API_USER'], :api_key => ENV['SENDGRID_API_KEY']
      end
    end

    it 'should send a message' do
      message.deliver.should == message
    end
  end

  describe '#deliver!' do
    before :all do
      Mail.defaults do
        delivery_method MultiMail::Sender::SendGrid, :api_user => ENV['SENDGRID_API_USER'], :api_key => ENV['SENDGRID_API_KEY'], :return_response => true
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