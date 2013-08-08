require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'multi_mail/sendgrid/sender'

describe MultiMail::Sender::SendGrid do
  let :message do
    Mail.new do
      date    Time.at(946702800)
      from    'foo@example.com'
      to      'bar@example.com'
      subject 'test'
      body    'hello'
    end
  end

  let :message_without_from do
    Mail.new do
      date    Time.at(946702800)
      to      'bar@example.com'
      subject 'test'
      body    'hello'
    end
  end

  let :message_without_to do
    Mail.new do
      date    Time.at(946702800)
      from    'foo@example.com'
      subject 'test'
      body    'hello'
    end
  end

  let :message_without_subject do
    Mail.new do
      date    Time.at(946702800)
      from    'foo@example.com'
      to      'bar@example.com'
      body    'hello'
    end
  end

  let :message_without_body do
    Mail.new do
      date    Time.at(946702800)
      from    'foo@example.com'
      to      'bar@example.com'
      subject 'test'
    end
  end

  describe '#initialize' do
    it 'should raise an error if :api_user is missing' do
      expect{
        message.delivery_method MultiMail::Sender::SendGrid, :api_key => 'xxx'
      }.to raise_error(ArgumentError, "Missing required arguments: api_user")
    end

    it 'should raise an error if :api_key is missing' do
      expect{
        message.delivery_method MultiMail::Sender::SendGrid, :api_user => 'xxx'
      }.to raise_error(ArgumentError, "Missing required arguments: api_key")
    end

    it 'should raise an error if :api_user is nil' do
      expect{
        message.delivery_method MultiMail::Sender::SendGrid, :api_user => nil, :api_key => 'xxx'
      }.to raise_error(ArgumentError, "Missing required arguments: api_user")
    end

    it 'should raise an error if :api_key is nil' do
      expect{
        message.delivery_method MultiMail::Sender::SendGrid, :api_user => 'xxx', :api_key => nil
      }.to raise_error(ArgumentError, "Missing required arguments: api_key")
    end

    it 'should raise an error if :api_user is invalid' do
      expect{
        message.delivery_method MultiMail::Sender::SendGrid, :api_user => 'xxx', :api_key => ENV['SENDGRID_API_KEY']
        message.deliver
      }.to raise_error(MultiMail::InvalidAPIKey, 'Bad username / password')
    end

    it 'should raise an error if :api_key is invalid' do
      expect{
        message.delivery_method MultiMail::Sender::SendGrid, :api_user => ENV['SENDGRID_API_USER'], :api_key => 'xxx'
        message.deliver
      }.to raise_error(MultiMail::InvalidAPIKey, 'Bad username / password')
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

    it 'should not send a message without a From header' do
      expect{message_without_from.deliver!}.to raise_error(MultiMail::MissingSender, 'Empty from email address (required)')
    end

    it 'should not send a message without a To header' do
      expect{message_without_to.deliver!}.to raise_error(MultiMail::MissingRecipients, 'Missing destination email')
    end

    it 'should not send a message without a subject' do
      expect{message_without_subject.deliver!}.to raise_error(MultiMail::MissingSubject, 'Missing subject')
    end

    it 'should not send a message without a body' do
      expect{message_without_body.deliver!}.to raise_error(MultiMail::MissingBody, 'Missing email body')
    end
  end
end