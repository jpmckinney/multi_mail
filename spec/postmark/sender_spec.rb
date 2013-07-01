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

  describe '#initialize' do
    it 'should raise an error if :api_key is missing' do
      expect{
        message.delivery_method MultiMail::Sender::Postmark
        message.deliver
      }.to raise_error(ArgumentError)
    end

    it 'should raise an error if :api_key is nil' do
      expect{
        message.delivery_method MultiMail::Sender::Postmark, :api_key => nil
        message.deliver
      }.to raise_error(ArgumentError)
    end
  end

  describe '#deliver' do
    before :all do
      Mail.defaults do
        delivery_method MultiMail::Sender::Postmark, :api_key => 'POSTMARK_API_TEST'
      end
    end

    it 'sends a message' do
      message.deliver.should == message
      message.delivered?.should == true
    end
  end
end
