require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'multi_mail/postmark/sender'

# @see https://github.com/wildbit/postmark-gem/blob/master/spec/unit/postmark/handlers/mail_spec.rb
# @see https://github.com/wildbit/postmark-gem/blob/master/spec/integration/mail_delivery_method_spec.rb
describe MultiMail::Sender::Postmark do
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
        message.delivery_method MultiMail::Sender::Postmark
        message.deliver
      }.to raise_error(ArgumentError, "Missing required arguments: :api_key")
    end

    it 'should raise an error if :api_key is nil' do
      expect{
        message.delivery_method MultiMail::Sender::Postmark, :api_key => nil
        message.deliver
      }.to raise_error(ArgumentError, "Missing required arguments: :api_key")
    end

    it 'should raise an error if :api_key is invalid' do
      expect{
        message.delivery_method MultiMail::Sender::Postmark, :api_key => 'xxx'
        message.deliver
      }.to raise_error(MultiMail::InvalidAPIKey)
    end
  end

  describe '#deliver' do
    before :all do
      Mail.defaults do
        delivery_method MultiMail::Sender::Postmark, :api_key => 'POSTMARK_API_TEST'
      end
    end

    it 'should send a message' do
      message.deliver.should == message
      message['Message-ID'].should_not be_nil # postmark gem
    end
  end

  describe '#deliver!' do
    before :all do
      Mail.defaults do
        delivery_method MultiMail::Sender::Postmark, :api_key => 'POSTMARK_API_TEST', :return_response => true
      end
    end

    it 'should send a message' do
      result = message.deliver!
      result.size.should == 10 # string keys are deprecated

      Time.parse(result[:submitted_at]).should be_within(1).of(Time.now)
      result[:to].should == "bar@example.com"
      result[:message_id].should match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/)
      result[:error_code].should == 0
      result[:message].should == 'Test job accepted'
    end

    it 'should not send an empty message' do
      expect{empty_message.deliver!}.to raise_error(MultiMail::InvalidMessage)
    end
  end
end
