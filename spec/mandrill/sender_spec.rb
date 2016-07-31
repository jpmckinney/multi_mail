require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

xdescribe MultiMail::Sender::Mandrill do
  let :message do
    Mail.new do
      from    'foo@example.com'
      to      'bit-bucket@test.smtp.org'
      subject 'test'
      body    'hello'
    end
  end

  let :empty_message do
    Mail.new
  end

  let :mailer do
    Class.new(ActionMailer::Base) do
      def welcome
        mail
      end
    end
  end

  let :mailer_with_delivery_method_set_by_class do
    Class.new(ActionMailer::Base) do
      default :delivery_method => :mandrill

      def welcome
        mail
      end
    end
  end

  let :mailer_with_delivery_method_set_by_method do
    Class.new(ActionMailer::Base) do
      def welcome
        mail(:delivery_method => :mandrill)
      end
    end
  end

  let :mailer_with_delivery_method_options_set_by_method do
    Class.new(ActionMailer::Base) do
      def welcome
        mail(:delivery_method_options => {:template_name => 'default'})
      end
    end
  end

  let :mailer_with_delivery_method_options_set_by_action do
    Class.new(ActionMailer::Base) do
      before_action :set_delivery_method_options

      def welcome
        mail
      end

    private

      def set_delivery_method_options
        mail.delivery_method.template_name = 'default'
      end
    end
  end

  shared_examples 'a sender' do
    it 'should send a message' do
      results = message.deliver!
      results.size.should == 1

      result = results.first
      result.size.should == 4

      result['reject_reason'].should == nil
      result['status'].should == 'sent'
      result['email'].should == 'bit-bucket@test.smtp.org'
      result['_id'].should match(/\A[0-9a-f]{32}\z/)
    end

    it 'should not send an empty message' do
      empty_message.deliver!.should == [] # response not saved
    end
  end

  describe '#initialize' do
    it 'should raise an error if :api_key is missing' do
      expect{
        message.delivery_method MultiMail::Sender::Mandrill
      }.to raise_error(ArgumentError, "Missing required arguments: api_key")
    end

    it 'should raise an error if :api_key is nil' do
      expect{
        message.delivery_method MultiMail::Sender::Mandrill, :api_key => nil
      }.to raise_error(ArgumentError, "Missing required arguments: api_key")
    end

    it 'should raise an error if :api_key is invalid' do
      expect{
        message.delivery_method MultiMail::Sender::Mandrill, :api_key => 'xxx'
        message.deliver
      }.to raise_error(MultiMail::InvalidAPIKey, 'Invalid API key')
    end

    it 'should raise an error if :template_name is invalid' do
      expect{
        message.delivery_method MultiMail::Sender::Mandrill, :api_key => ENV['MANDRILL_API_KEY'], :template_name => 'nonexistent'
        message.deliver
      }.to raise_error(MultiMail::InvalidTemplate, 'No such template "nonexistent"')
    end

    it 'should transform send_at to a string if it is not a string' do
      sender = MultiMail::Sender::Mandrill.new(:api_user => '', :api_key => '', 'send_at' => Time.at(981203696))
      sender.send_at.should == '2001-02-03 12:34:56'
    end

    it 'should not transform send_at to a string if it is a string' do
      sender = MultiMail::Sender::Mandrill.new(:api_user => '', :api_key => '', 'send_at' => '2001-02-03 12:34:56')
      sender.send_at.should == '2001-02-03 12:34:56'
    end

    it 'should have default settings' do
      sender = MultiMail::Sender::Mandrill.new(:api_key => '')

      sender.api_key.should == ''
      sender.async.should   == false
      sender.ip_pool.should == nil
      sender.send_at.should == nil
      sender.template_name.should == nil
      sender.template_content.should == nil
    end

    it 'should assign custom settings' do
      sender = MultiMail::Sender::Mandrill.new({
        :api_key => 'xxx',
        :async => true,
        :ip_pool => 'Main Pool',
        :send_at => 'example send_at',
        :template_name => 'foo',
        :template_content => [{'name' => 'bar', 'content' => 'baz'}],
      })

      sender.api_key.should == 'xxx'
      sender.async.should   == true
      sender.ip_pool.should == 'Main Pool'
      sender.send_at.should == 'example send_at'
      sender.template_name.should == 'foo'
      sender.template_content.should == [{'name' => 'bar', 'content' => 'baz'}]
    end
  end

  describe '#parameters' do
    it 'should allow true, false and nil values' do
      [true, false, nil].each do |value|
        sender = MultiMail::Sender::Mandrill.new({
          :api_key => 'xxx',
          :track => {
            :clicks => value,
          }
        })

        sender.parameters.should == {:track_clicks => value}
      end
    end

    it 'should transform "yes" and "no" values' do
      sender = MultiMail::Sender::Mandrill.new({
        :api_key => 'xxx',
        :track => {
          :opens => 'no',
          :clicks => 'yes',
        }
      })

      sender.parameters.should == {:track_opens => false, :track_clicks => true}
    end

    it 'should ignore "htmlonly" values' do
      sender = MultiMail::Sender::Mandrill.new({
        :api_key => 'xxx',
        :track => {
          :clicks => 'htmlonly',
        }
      })

      sender.parameters.should == {}
    end
  end

  describe '#deliver' do
    before :all do
      Mail.defaults do
        delivery_method MultiMail::Sender::Mandrill, :api_key => ENV['MANDRILL_API_KEY']
      end
    end

    it 'should send a message' do
      message.deliver.should == message
    end
  end

  describe '#deliver!' do
    context 'when :template_name is set' do
      before :all do
        Mail.defaults do
          delivery_method MultiMail::Sender::Mandrill, :api_key => ENV['MANDRILL_API_KEY'], :return_response => true, :template_name => 'default'
        end
      end

      it_behaves_like 'a sender'
    end

    context 'when :template_name is not set' do
      before :all do
        Mail.defaults do
          delivery_method MultiMail::Sender::Mandrill, :api_key => ENV['MANDRILL_API_KEY'], :return_response => true
        end
      end

      it_behaves_like 'a sender'
    end
  end

  # @see https://github.com/rails/rails/blob/3e36db4406beea32772b1db1e9a16cc1e8aea14c/actionmailer/test/delivery_methods_test.rb
  context 'with ActionMailer' do
    before :all do
      ActionMailer::Base.view_paths = File.expand_path('../../fixtures', __FILE__)
      ActionMailer::Base.add_delivery_method :mandrill, MultiMail::Sender::Mandrill, :api_key => ENV['MANDRILL_API_KEY']
    end

    context 'when setting delivery method' do
      context 'with delivery method set globally' do
        it 'should send a message' do
          ActionMailer::Base.delivery_method = :mandrill

          email = mailer.welcome.deliver_now
          email.delivery_method.should be_a(MultiMail::Sender::Mandrill)

          ActionMailer::Base.delivery_method = :smtp
        end
      end

      context 'with delivery method set by a class' do
        it 'should send a message' do
          Mail::SMTP.any_instance.stub(:deliver!)
          email = mailer.welcome.deliver_now
          email.delivery_method.should be_a(Mail::SMTP)

          email = mailer_with_delivery_method_set_by_class.welcome.deliver_now
          email.delivery_method.should be_a(MultiMail::Sender::Mandrill)
        end
      end

      context 'with delivery method set by a method' do
        it 'should send a message' do
          Mail::SMTP.any_instance.stub(:deliver!)
          email = mailer.welcome.deliver_now
          email.delivery_method.should be_a(Mail::SMTP)

          email = mailer_with_delivery_method_set_by_method.welcome.deliver_now
          email.delivery_method.should be_a(MultiMail::Sender::Mandrill)
        end
      end
    end

    context 'when setting delivery method options' do
      before :all do
        ActionMailer::Base.delivery_method = :mandrill
      end

      context 'with delivery method options set globally' do
        it 'should send a message' do
          old_settings = ActionMailer::Base.mandrill_settings

          email = mailer.welcome.deliver_now
          email.delivery_method.template_name.should == nil

          ActionMailer::Base.mandrill_settings = old_settings.merge(:template_name => 'default')

          email = mailer.welcome.deliver_now
          email.delivery_method.template_name.should == 'default'

          ActionMailer::Base.mandrill_settings = old_settings
        end
      end

      context 'with delivery method options set by a method' do
        it 'should send a message' do
          email = mailer.welcome.deliver_now
          email.delivery_method.template_name.should == nil

          email = mailer_with_delivery_method_options_set_by_method.welcome.deliver_now
          email.delivery_method.template_name.should == 'default'
        end
      end

      context 'with delivery method options set by an action' do
        it 'should send a message' do
          email = mailer.welcome.deliver_now
          email.delivery_method.template_name.should == nil

          email = mailer_with_delivery_method_options_set_by_action.welcome.deliver_now
          email.delivery_method.template_name.should == 'default'
        end
      end
    end
  end
end
