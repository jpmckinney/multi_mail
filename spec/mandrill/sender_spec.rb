require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'multi_mail/mandrill/sender'

describe MultiMail::Sender::Mandrill do 
  context 'after initialization' do 
    let :service do
      MultiMail::Sender.new({
        :provider => :mandrill,
        :api_key => 'mE2bie6bBEioJG40ZbWZ6g'
        })
    end

    describe '#deliver' do
      it 'should deliver a message' do 
        message = Mail.new({
          :sender =>    'alexi@opennorth.ca',
          :to =>      'alexio2@mac.com',
          :subject => 'this is a test',
          :body =>    'test text body',
        })

        service.deliver!(message)
      end
    end
  end

  context 'after initialization without api_key' do
    let :service do 
      MultiMail::Sender.new({:provider => :mandrill})
    end

    it 'should raise an error' do
      message = Mail.new({
        :from =>    'test@example.com',
        :to =>      'example@test.com',
        :subject => 'this is a test',
        :body =>    'test text body',
      })
      expect{ service.deliver!(message) }.to raise_error
    end
  end
end