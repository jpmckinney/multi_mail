require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

# Account disabled.
xdescribe MultiMail::Sender::Mailgun do
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
    it 'should raise an error if :api_key is missing' do
      expect{
        message.delivery_method MultiMail::Sender::Mailgun, :domain => 'xxx'
      }.to raise_error(ArgumentError, "Missing required arguments: api_key")
    end

    it 'should raise an error if :domain is missing' do
      expect{
        message.delivery_method MultiMail::Sender::Mailgun, :api_key => 'xxx'
      }.to raise_error(ArgumentError, "Missing required arguments: domain")
    end

    it 'should raise an error if :api_key is nil' do
      expect{
        message.delivery_method MultiMail::Sender::Mailgun, :api_key => nil, :domain => 'xxx'
      }.to raise_error(ArgumentError, "Missing required arguments: api_key")
    end

    it 'should raise an error if :domain is nil' do
      expect{
        message.delivery_method MultiMail::Sender::Mailgun, :api_key => 'xxx', :domain => nil
      }.to raise_error(ArgumentError, "Missing required arguments: domain")
    end

    it 'should raise an error if :api_key is invalid' do
      expect{
        message.delivery_method MultiMail::Sender::Mailgun, :api_key => 'xxx', :domain => 'multimail.mailgun.org'
        message.deliver
      }.to raise_error(MultiMail::InvalidAPIKey)
    end

    it 'should raise an error if :domain is invalid' do
      expect{
        message.delivery_method MultiMail::Sender::Mailgun, :api_key => ENV['MAILGUN_API_KEY'], :domain => 'xxx'
        message.deliver
      }.to raise_error(MultiMail::InvalidRequest, "Domain not found: xxx")
    end

    it 'should assign custom settings' do
      sender = MultiMail::Sender::Mailgun.new(:api_key => 'xxx', :domain => 'xxx')

      sender.api_key.should == 'xxx'
      sender.domain.should  == 'xxx'
    end
  end

  describe '#parameters' do
    it 'should allow "yes", "no" and "htmlonly" values' do
      %w(yes no htmlonly).each do |value|
        sender = MultiMail::Sender::Mailgun.new({
          :api_key => 'xxx',
          :domain => 'xxx',
          :track => {
            :clicks => value,
          }
        })

        sender.parameters.should == {:'o:tracking-clicks' => value}
      end
    end

    it 'should transform true and false values' do
      sender = MultiMail::Sender::Mailgun.new({
        :api_key => 'xxx',
        :domain => 'xxx',
        :track => {
          :opens => false,
          :clicks => true,
        }
      })

      sender.parameters.should == {:'o:tracking-opens' => 'no', :'o:tracking-clicks' => 'yes'}
    end

    it 'should ignore nil values' do
      sender = MultiMail::Sender::Mailgun.new({
        :api_key => 'xxx',
        :domain => 'xxx',
        :track => {
          :clicks => nil,
        }
      })

      sender.parameters.should == {}
    end
  end

  describe '#deliver' do
    before :all do
      Mail.defaults do
        delivery_method MultiMail::Sender::Mailgun, :api_key => ENV['MAILGUN_API_KEY'], :domain => 'multimail.mailgun.org', 'o:testmode' => 'yes'
      end
    end

    it 'should send a message' do
      message.deliver.should == message
    end
  end

  describe '#deliver!' do
    before :all do
      Mail.defaults do
        delivery_method MultiMail::Sender::Mailgun, :api_key => ENV['MAILGUN_API_KEY'], :domain => 'multimail.mailgun.org', 'o:testmode' => 'yes', :return_response => true
      end
    end

    it 'should send a message' do
      result = message.deliver!
      result.size.should == 2

      result['message'].should == 'Queued. Thank you.'
      result['id'].should match(/<\S+@\S+>/)
    end

    it 'should not send a message without a From header' do
      expect{message_without_from.deliver!}.to raise_error(MultiMail::MissingSender, "'from' parameter is missing")
    end

    it 'should not send a message without a To header' do
      expect{message_without_to.deliver!}.to raise_error(MultiMail::MissingRecipients, "'to' parameter is missing")
    end

    it 'should send a message without a subject' do
      expect{message_without_subject.deliver!}.to_not raise_error
    end

    it 'should not send a message without a body' do
      expect{message_without_body.deliver!}.to raise_error(MultiMail::MissingBody, "Need at least one of 'text' or 'html' parameters specified")
    end
  end
end
