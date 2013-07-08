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
      }.to raise_error(ArgumentError, "Missing required arguments: api_key")
    end

    it 'should raise an error if :api_key is nil' do
      expect{
        message.delivery_method MultiMail::Sender::Mandrill, :api_key => nil
      }.to raise_error(ArgumentError, "Missing required arguments: api_key")
    end

    it 'should raise an error if :api_key is invalid' do
      expect{
        message.delivery_method MultiMail::Sender::Mandrill, :api_key => 'xxx'
        message.deliver
      }.to raise_error(MultiMail::InvalidAPIKey, 'Invalid API key')
    end

    it 'should have default settings' do
      sender = MultiMail::Sender::Mandrill.new(:api_key => '')

      sender.api_key.should == ''
      sender.async.should   == false
      sender.ip_pool.should == nil
      sender.send_at.should == nil
    end

    it 'should assign custom settings' do
      sender = MultiMail::Sender::Mandrill.new({
        :api_key => 'xxx',
        :async   => true,
        :ip_pool => 'Main Pool',
        :send_at => 'example send_at',
      })

      sender.api_key.should == 'xxx'
      sender.async.should   == true
      sender.ip_pool.should == 'Main Pool'
      sender.send_at.should == 'example send_at'
    end
  end

  describe '#parameters' do
    it 'should allow true, false and nil values' do
      [true, false, nil].each do |value|
        sender = MultiMail::Sender::Mandrill.new({
          :api_key => 'xxx',
          :track => {
            :clicks => value,
          }
        })

        sender.parameters.should == {:track_clicks => value}
      end
    end

    it 'should transform "yes" and "no" values' do
      sender = MultiMail::Sender::Mandrill.new({
        :api_key => 'xxx',
        :track => {
          :opens => 'no',
          :clicks => 'yes',
        }
      })

      sender.parameters.should == {:track_opens => false, :track_clicks => true}
    end

    it 'should ignore "htmlonly" values' do
      sender = MultiMail::Sender::Mandrill.new({
        :api_key => 'xxx',
        :track => {
          :clicks => 'htmlonly',
        }
      })

      sender.parameters.should == {}
    end
  end

  describe '#deliver' do
    before :all do
      Mail.defaults do
        delivery_method MultiMail::Sender::Mandrill, :api_key => ENV['MANDRILL_API_KEY']
      end
    end

    it 'should send a message' do
      message.deliver.should == message
    end
  end

  describe '#deliver!' do
    before :all do
      Mail.defaults do
        delivery_method MultiMail::Sender::Mandrill, :api_key => ENV['MANDRILL_API_KEY'], :return_response => true
      end
    end

    it 'should send a message' do
      results = message.deliver!
      results.size.should == 1

      result = results.first
      result.size.should == 4

      result['reject_reason'].should == 'soft-bounce' # sometimes nil
      result['status'].should == 'sent'
      result['email'].should == 'bar@example.com'
      result['_id'].should match(/\A[0-9a-f]{32}\z/)
    end

    it 'should not send an empty message' do
      empty_message.deliver!.should == [] # response not saved
    end
  end
end
