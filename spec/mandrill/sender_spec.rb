require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'multi_mail/mandrill/sender'

describe MultiMail::Sender::Mandrill do 
  context 'after initialization with api_key' do

    let :service do
      MultiMail::Sender.new({
        :provider => :mandrill,
        :api_key => ENV['MANDRILL_API'],
        :message_options => {
          :important => false 
        },
        :return_response => true,
        })
    end

    let :message do 
      Mail.new({
        :from =>    'test@example.com',
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
        delivery_method Mail::Postmark, :api_key => "POSTMARK_API_TEST"
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
        from "sender@mandrill.com"
        to "@mandrill.com"
        delivery_method Mail::Postmark, :api_key => "POSTMARK_API_TEST"
      end
    end



    describe '#deliver' do
 
      it 'sends email' do
        service.deliver!(message)[0]["status"].should eq "sent"
      end

      it 'sends to correct recipients' do
        service.deliver!(message).each_with_index do |response,i|
          response["email"].should eq message[:to].to_s.split(',')[i].strip
        end
      end

      it 'sends to multiple recipients' do
        service.deliver!(message).size.should eq 2
      end

      it 'returns mandrill response' do
        response = service.deliver!(message)
        response.each do |r|
          r.should have_key "email"
          r.should have_key "status"
          r.should have_key "reject_reason"
        end
      end

      it 'delivers a tagged message' do
        service.deliver!(tagged_message)[0]["status"].should eq "sent"
      end

      it 'delivers a message with attachment' do
        service.deliver!(message_with_attachment)[0]["status"].should eq "queued"
      end

      it 'delivers multipart emails' do
        service.deliver!(multipart_message)[0]['status'].should eq "sent"
      end

      it 'rejects an invalid email' do
        p service.deliver!(message_with_invalid_to) 
        expect { service.deliver!(message_with_no_body) }.to raise_error
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