require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

# @see https://github.com/mikel/mail/blob/master/lib/mail/network/delivery_methods/test_mailer.rb
class TestMailer
  include MultiMail::Sender::Base

  def initialize(options = {})
    # Do nothing.
  end

  def self.deliveries
    @deliveries ||= []
  end

  def deliver!(mail)
    self.class.deliveries << mail
  end
end

describe MultiMail::Sender::Base do
  let :message do
    Mail.new do
      from    'foo@example.com'
      to      'bar@example.com'
      subject 'test'
      body    'hello'
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
end
