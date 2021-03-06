require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MultiMail::Sender::Base do
  let :klass do
    Class.new do
      include MultiMail::Sender::Base

      requires :foo
    end
  end

  describe '#initialize' do
    it 'should symbolize keys' do
      instance = klass.new('foo' => 1, :bar => 2, nil => 3, true => 4, false => 5, 6 => 6)
      instance.settings.should == {
        :foo  => 1,
        :bar  => 2,
        nil   => 3,
        true  => 4,
        false => 5,
        6     => 6,
      }
    end

    it 'should have default settings' do
      sender = klass.new(:foo => '')
      sender.tracking.should == {}
    end

    it 'should assign custom settings' do
      sender = klass.new(:foo => '', :track => {:opens => true})
      sender.tracking.should == {:opens => true}
    end
  end
end
