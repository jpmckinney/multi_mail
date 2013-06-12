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

    let :message do
      message = Mail.new({
        :from =>    'from@example.com',
        :to =>      ['to@example.com','to2@example.com'],
        :subject => 'this is a test',
        :body =>    'test text body',
      })
    end

    let :tagged_message do
      message.tap do |m|
        m.tag "postmark-gem"
      end
    end

    let :message_with_no_body do
      Mail.new do
        from "sender@postmarkapp.com"
        to "recipient@postmarkapp.com"
        delivery_method Mail::Postmark, :api_key => "POSTMARK_API_TEST"
      end
    end

    let :message_with_attachment do
      message.tap do |msg|
        msg.attachments["valid"] = response('postmark', 'valid')
      end
    end

    let :message_with_invalid_to do
      Mail.new do
        from "sender@postmarkapp.com"
        to "@postmarkapp.com"
        delivery_method Mail::Postmark, :api_key => "POSTMARK_API_TEST"
      end
    end

    describe '#deliver' do
      it 'sends email' do
        service.deliver!(message)
        message.delivered.should eq true
      end

      it 'sends to correct recipients' do
        response = service.deliver!(message).postmark_response
        response["To"].should eq message[:to].to_s
      end

      it 'updates a message object with full postmark response' do
        expect { service.deliver!(message) }.to change{message.postmark_response}.from(nil)
      end

      it 'delivers a tagged message' do
        expect { service.deliver!(tagged_message) }.to change{message.delivered?}.to(true)
      end

      it 'delivers a message with attachment' do
        expect { service.deliver!(message_with_attachment) }.to change{message_with_attachment.delivered?}.to(true)
      end

      it 'rejects invalid email address' do
        expect { service.deliver!(message_with_invalid_to) }.to raise_error
      end

    end



  end

  context 'after initialization without api_key' do
    let :service do 
      MultiMail::Sender.new({:provider => :postmark})
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