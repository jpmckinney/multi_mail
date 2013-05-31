require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MultiMail::Sender::Base do
  before :all do
    TestMailer = Class.new(MultiMail::Service) do
      include MultiMail::Sender::Base

      def initialize(values)
        self.settings = values.dup
      end

      def deliver!(mail)
        check_delivery_params(mail)
        self.class.deliveries << mail
      end

      def self.deliveries
        @deliveries ||= []
      end
    end
  end

  describe '#deliver!' do
    it 'should deliver a message' do
      expect{
        message = Mail.new do
          delivery_method TestMailer
          to 'foo@example.com'
          from 'bar@example.com'
          subject 'test'
          body 'hello'
        end
        message.deliver
      }.to change(TestMailer.deliveries, :size).by(1)
    end
  end
end
