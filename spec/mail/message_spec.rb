require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Mail::Message do
  # @see https://github.com/mikel/mail/blob/master/spec/mail/message_spec.rb#L491
  describe 'setting headers' do
    it 'should accept them in block form' do
      message = Mail.new do
        tag 'foo'
      end
      message.tag.should == 'foo'
    end

    it 'should accept them in assignment form' do
      message = Mail.new
      message.tag = 'foo'
      message.tag.should == 'foo'
    end

    it 'should accept them in key, value form as symbols' do
      message = Mail.new
      message[:tag] = 'foo'
      message.tag.should == 'foo'
    end

    it 'should accept them in key, value form as strings' do
      message = Mail.new
      message['tag'] = 'foo'
      message.tag.should == 'foo'
    end

    it 'should accept them as a hash with symbols' do
      message = Mail.new({
        :tag => 'foo',
      })
      message.tag.should == 'foo'
    end

    it 'should accept them as a hash with strings' do
      message = Mail.new({
        'tag' => 'foo',
      })
      message.tag.should == 'foo'
    end
  end
end
