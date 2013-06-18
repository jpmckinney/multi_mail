require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'multi_mail/simple/sender'

describe MultiMail::Sender::Simple do 
  include Mail::Matchers
  context 'no initialization' do 

    let :service do
      MultiMail::Sender.new({
        :provider => :simple,
        :return_response => true
      })
    end

    let :message do 
      Mail.new do
         from    'me@example.com'
         to      'you@exmple.com'
         subject 'Here is the image you wanted'
         body     'bla bla bla'
        # body    File.read('body.txt')
        #add_file '/full/path/to/somefile.png'
      end
    end

    describe '#deliver' do
      it 'should send email' do 
        message.delivery_method :smtp, { 
          :address              => 'smtp.gmail.com',
          :port                 => 25,
          # :domain               => 'smtp.gmail.com',
          :user_name            => ENV['GMAIL_USERNAME'],
          :password             => ENV['GMAIL_PASSWORD'],
          :authentication       => 'plain',
          :enable_starttls_auto => true  }
        service.deliver!(message)['Message-ID'].should_not be_nil        
      end

    end
  end

end