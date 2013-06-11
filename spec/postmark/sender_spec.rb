require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'multi_mail/postmark/sender'

describe MultiMail::Sender::Postmark do 
  context 'after initialization' do 
    let :service do
      MultiMail::Sender.new({
        :provider => :postmark,
        :api_key => 'POSTMARK_API_TEST'
        })
    end

    describe '#deliver' do
      it 'should deliver a message' do 
        message = Mail.new({
          :from =>    'test@example.com',
          :to =>      'emaple@test.com',
          :subject => 'this is a test',
          :body =>    'test text body',
        })
        service.deliver!(message)
      end
    end
  end

  context 'after initialization without api_key' do
    let :service do 
      MultiMail::Sender.new({:provider => :postmark})
    end

    it 'should raise an error' do
      message = Mail.new({
        :from =>    'alexi@opennorth.ca',
        :to =>      'alexio2@mac.com',
        :subject => 'this is a test',
        :body =>    'There\'s a snake in my boots',
      })
      expect{ service.deliver!(message) }.to raise_error
    end
  end
end