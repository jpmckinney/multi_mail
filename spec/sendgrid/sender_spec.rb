require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'multi_mail/sendgrid/sender'

describe MultiMail::Sender::SendGrid do
  include Mail::Matchers
  context 'after initialization' do 
    
    let :service do
      MultiMail::Sender.new({
        :provider => :sendgrid,
        :user_name => ENV['SENDGRID_USERNAME'],
        :api_key => ENV['SENDGRID_API_KEY'],
        :message_options => {
          "replyto" => 'alexio2@mac.com'
        },
        :return_response => true
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
      end
    end

    let :message_with_attachment do
      message.tap do |msg|
        msg.attachments["valid"] = response('postmark', 'valid')
      end
    end

    let :multipart_message do

      html_part = Mail::Part.new do
        content_type 'text/html; charset=UTF-8'
        body '<h1>This is HTML</h1>'
      end
      message.tap do |msg|
        msg.html_part = html_part
      end
      
    end

    let :message_with_invalid_to do
      Mail.new do
        from "sender@postmarkapp.com"
        to "@postmarkapp.com"
      end
    end
    describe '#deliver' do

      it 'sends email' do
        service.deliver!(message).should eq "{\"message\":\"success\"}"
      end

      it 'sends to correct recipients' do
        service.deliver!(message).should eq "{\"message\":\"success\"}"
      end

 #     it 'sends to multiple recipients' do 
 #       response = service.deliver!(message)
 #       response["To"].split(',').size.should eq 2
 #     end

 #     it 'updates a message object with full postmark response' do
#        expect { service.deliver!(message) }.to change{message.postmark_response}.from(nil)
#      end

#      it 'delivers a tagged message' do
#        expect { service.deliver!(tagged_message) }.to change{message.delivered?}.to(true)
#      end

      it 'delivers a message with attachment' do
        service.deliver!(message_with_attachment).should eq "{\"message\":\"success\"}"
      end

      it 'delivers multipart message' do
        service.deliver!(multipart_message).should eq "{\"message\":\"success\"}"
      end

      it 'rejects invalid email' do
        expect { service.deliver!(message_with_invalid_to) }.to raise_error
        service.deliver!(message_with_no_body).should eq "{\"message\": \"error\", \"errors\": [\"Missing subject\"]}"
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