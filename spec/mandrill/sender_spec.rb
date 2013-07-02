require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'multi_mail/mandrill/sender'

describe MultiMail::Sender::Mandrill do 
  let :message do
    Mail.new do
      from    'foo@example.com'
      to      'bar@example.com'
      subject 'test'
      body    'hello'
    end
  end

  let :empty_message do
    Mail.new
  end

  describe '#initialize' do
    it 'should raise an error if :api_key is missing' do
      expect{
        message.delivery_method MultiMail::Sender::Mandrill
        message.deliver
      }.to raise_error(ArgumentError, "Missing required arguments: :api_key")
    end

    it 'should raise an error if :api_key is nil' do
      expect{
        message.delivery_method MultiMail::Sender::Mandrill, :api_key => nil
        message.deliver
      }.to raise_error(ArgumentError, "Missing required arguments: :api_key")
    end

    it 'should raise an error if :api_key is invalid' do
      expect{
        message.delivery_method MultiMail::Sender::Mandrill, :api_key => 'xxx'
        message.deliver
      }.to raise_error(ArgumentError, "Invalid API key")
    end

    it 'should have default settings' do
      sender = MultiMail::Sender::Mandrill.new

      sender.api_key.should == nil
      sender.async.should   == false
      sender.ip_pool.should == nil
      sender.send_at.should == nil
    end

    it 'should assign custom settings' do
      sender = MultiMail::Sender::Mandrill.new({
        :api_key         => ENV['MANDRILL_API'],
        :async           => true,
        :ip_pool         => 'Main Pool',
        :send_at         => 'example send_at',
      })

      sender.api_key.should == ENV['MANDRILL_API']
      sender.async.should   == true
      sender.ip_pool.should == 'Main Pool'
      sender.send_at.should == 'example send_at'
    end
  end

  describe '#deliver' do
    before :all do
      Mail.defaults do
        delivery_method MultiMail::Sender::Mandrill, :api_key => ENV['MANDRILL_API']
      end
    end

    it 'should send a message' do
      message.deliver.should == message
    end
  end

  describe '#deliver!' do
    before :all do
      Mail.defaults do
        delivery_method MultiMail::Sender::Mandrill, :api_key => ENV['MANDRILL_API'], :return_response => true
      end
    end

    it 'should send a message' do
      results = message.deliver!
      results.size.should == 1

      result = results.first
      result.size.should == 4

      result['reject_reason'].should == nil
      result['status'].should == "sent"
      result['email'].should == "bar@example.com"
      result['_id'].should match(/\A[0-9a-f]{32}\z/)
    end

    it 'should not send an empty message' do
      empty_message.deliver!.should == []
    end
  end
end
