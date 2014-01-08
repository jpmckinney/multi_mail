require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

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
    it 'should raise an error if :api_key is missing' do
      expect{
        message.delivery_method MultiMail::Sender::Postmark
      }.to raise_error(ArgumentError, "Missing required arguments: api_key")
    end

    it 'should raise an error if :api_key is nil' do
      expect{
        message.delivery_method MultiMail::Sender::Postmark, :api_key => nil
      }.to raise_error(ArgumentError, "Missing required arguments: api_key")
    end

    it 'should raise an error if :api_key is invalid' do
      expect{
        message.delivery_method MultiMail::Sender::Postmark, :api_key => 'xxx'
        message.deliver
      }.to raise_error(MultiMail::InvalidAPIKey, 'Bad or missing server or user API token.')
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
      result.size.should == 5

      Time.parse(result['SubmittedAt']).should be_within(5).of(Time.now)
      result['To'].should == "bar@example.com"
      result['MessageID'].should match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/)
      result['ErrorCode'].should == 0
      result['Message'].should == 'Test job accepted'
    end

    it 'should not send a message without a From header' do
      expect{message_without_from.deliver!}.to raise_error(MultiMail::MissingSender, "Invalid 'From' value.")
    end

    it 'should not send a message without a To header' do
      expect{message_without_to.deliver!}.to raise_error(MultiMail::MissingRecipients, 'Zero recipients specified')
    end

    it 'should send a message without a subject' do
      expect{message_without_subject.deliver!}.to_not raise_error
    end

    it 'should not send a message without a body' do
      expect{message_without_body.deliver!}.to raise_error(MultiMail::MissingBody, 'Provide either email TextBody or HtmlBody or both.')
    end
  end
end
