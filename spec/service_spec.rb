require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe MultiMail::Service do
  class MultiMail::Mock < MultiMail::Service
    requires :required_argument1, :required_argument2
    recognizes :optional_argument1, :optional_argument2

    def valid?(params)
      params['foo'] == 1
    end

    def transform(params)
      Mail.new
    end
  end

  describe '#initialize' do
    it 'should validate options' do
      MultiMail::Mock.should_receive(:validate_options).with(:required_argument1 => 1, :required_argument2 => 1).once
      MultiMail.new({
        :provider => :mock,
        :required_argument1 => 1,
        :required_argument2 => 1,
      })
    end
  end

  describe '#process' do
    before :all do
      @service = MultiMail.new({
        :provider => :mock,
        :required_argument1 => 1,
        :required_argument2 => 1,
      })
    end

    it 'should parse the request' do
      MultiMail::Mock.should_receive(:parse).with('foo' => 1).once.and_return('foo' => 1)
      @service.process('foo' => 1)
    end

    it 'should transform the request if the request is valid' do
      @service.process('foo' => 1).should be_a(Mail::Message)
    end

    it 'raise an error if the request is invalid' do
      expect{ @service.process('foo' => 0) }.to raise_error(MultiMail::Service::ForgedRequest)
    end
  end

  describe '#parse' do
    it 'should parse raw POST data' do
      MultiMail::Mock.parse('foo=1&bar=1&bar=1').should == {'foo' => '1', 'bar' => ['1', '1']}
    end

    it 'should pass-through a hash' do
      MultiMail::Mock.parse('foo' => 1).should == {'foo' => 1}
    end

    it 'should raise an error if the argument is invalid' do
      expect{ MultiMail::Mock.parse(1) }.to raise_error(ArgumentError, "Can't handle Fixnum webhook content")
    end
  end

  describe '#requires' do
    it 'should return required arguments' do
      MultiMail::Mock.requirements.should == [:required_argument1, :required_argument2]
    end
  end

  describe '#recognizes' do
    it 'should return optional arguments' do
      MultiMail::Mock.recognized.should == [:optional_argument1, :optional_argument2]
    end
  end

  describe '#validate_options' do
    it 'should not raise an error if the arguments are valid' do
      expect{
        MultiMail::Mock.validate_options({
          :required_argument1 => 1,
          :required_argument2 => 1,
        })
      }.to_not raise_error
    end

    it 'should raise an error if a required argument is missing' do
      expect{
        MultiMail::Mock.validate_options({
          :optional_argument1 => 1,
          :optional_argument2 => 1,
        })
      }.to raise_error(ArgumentError, "Missing required arguments: required_argument1, required_argument2")
    end

    it 'should raise an error if an argument is not recognized' do
      expect{
        MultiMail::Mock.validate_options({
          :required_argument1 => 1,
          :required_argument2 => 1,
          'foo' => 1,
        })
      }.to raise_error(ArgumentError, "Unrecognized arguments: foo")
    end
  end
end
