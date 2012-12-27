require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MultiMail::Receiver::Base do
  let :klass do
    Class.new(MultiMail::Service) do
      include MultiMail::Receiver::Base

      def valid?(params)
        params['foo'] == 1
      end

      def transform(params)
        [Mail.new]
      end
    end
  end

  describe '#process' do
    before :all do
      @service = klass.new
    end

    it 'should parse the request' do
      klass.should_receive(:parse).with('foo' => 1).once.and_return('foo' => 1)
      @service.process('foo' => 1)
    end

    it 'should transform the request if the request is valid' do
      @service.should_receive(:transform).with('foo' => 1).once
      @service.process('foo' => 1)
    end

    it 'raise an error if the request is invalid' do
      expect{ @service.process('foo' => 0) }.to raise_error(MultiMail::ForgedRequest)
    end
  end

  describe '#parse' do
    it 'should parse raw POST data' do
      klass.parse('foo=1&bar=1&bar=1').should == {'foo' => '1', 'bar' => ['1', '1']}
    end

    it 'should pass-through a hash' do
      klass.parse('foo' => 1).should == {'foo' => 1}
    end

    it 'should raise an error if the argument is invalid' do
      expect{ klass.parse(1) }.to raise_error(ArgumentError, "Can't handle Fixnum input")
    end
  end
end
