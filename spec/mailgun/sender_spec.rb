require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'multi_mail/mailgun/sender'

describe MultiMail::Sender::Mailgun do
  context 'after initialization' do 
    
    let :service do
      MultiMail::Sender.new({
        :provider => :mailgun,
        :api_key => ENV['MAILGUN_API_KEY'],
        :domain_name => ENV['MAILGUN_DOMAIN'],
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
        m[:tag] = "postmark-gem"
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
        msg.attachments["valid.txt"] = response('postmark', 'valid')
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
        service.deliver!(message).should include("Queued. Thank you.") 
      end

      # it 'sends to correct recipients' do
      #   service.deliver!(message).should eq "{\"message\":\"success\"}"
      # end

      # it 'sends to multiple recipients' do 
      #   response = service.deliver!(message)
      #   response["To"].split(',').size.should eq 2
      # end
 
      # it 'updates a message object with full postmark response' do
      #   expect { service.deliver!(message) }.to change{message.postmark_response}.from(nil)
      # end

      it 'delivers a tagged message' do
        service.deliver!(tagged_message).should include("Queued. Thank you.") 
      end

      it 'delivers a message with attachment' do
        p message_with_attachment.class
        service.deliver!(message_with_attachment).should include("Queued. Thank you.") 
      end

      it 'delivers multipart message' do
        service.deliver!(multipart_message).should include("Queued. Thank you.") 
      end

      it 'rejects invalid email' do
        expect { service.deliver!(message_with_invalid_to) }.to raise_error
        expect { service.deliver!(message_with_no_body) }.to raise_error
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