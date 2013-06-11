require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'multi_mail/postmark/sender'

describe MultiMail::Sender::Postmark do 
  context 'after initialization' do 
    let :service do
      MultiMail::Sender.new({
        :provider => :postmark,
        :api_key => 'bf200928-2fd2-42cf-af94-122f03fc6fb7'
        })
    end

    describe '#deliver' do
      it 'should deliver a message' do 
        message = Mail.new({
          :from =>    'alexi@opennorth.ca',
          :to =>      'alexio2@mac.com',
          :subject => 'this is a test',
          :body =>    'There\'s a snake in my boots',
        })
        service.deliver!(message)
      end
    end
  end
end