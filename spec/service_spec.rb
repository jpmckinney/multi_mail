require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe MultiMail::Service do
  let :klass do
    Class.new(MultiMail::Service) do
      requires :required_argument1, :required_argument2
      recognizes :optional_argument1, :optional_argument2
    end
  end

  describe '#initialize' do
    it 'should validate options' do
      klass.should_receive(:validate_options).with(:required_argument1 => 1, :required_argument2 => 1).once
      klass.new(:required_argument1 => 1, :required_argument2 => 1)
    end
  end

  describe '#requires' do
    it 'should return required arguments' do
      klass.requirements.should == [:required_argument1, :required_argument2]
    end
  end

  describe '#recognizes' do
    it 'should return optional arguments' do
      klass.recognized.should == [:optional_argument1, :optional_argument2]
    end
  end

  describe '#validate_options' do
    it 'should not raise an error if the arguments are valid' do
      expect{
        klass.validate_options({
          :required_argument1 => 1,
          :required_argument2 => 1,
        })
      }.to_not raise_error
    end

    it 'should raise an error if a required argument is missing' do
      expect{
        klass.validate_options({
          :optional_argument1 => 1,
          :optional_argument2 => 1,
        })
      }.to raise_error(ArgumentError, "Missing required arguments: required_argument1, required_argument2")
    end

    it 'should raise an error if an argument is not recognized' do
      expect{
        klass.validate_options({
          :required_argument1 => 1,
          :required_argument2 => 1,
          :foo => 1,
          :bar => 1,
        })
      }.to raise_error(ArgumentError, "Unrecognized arguments: bar, foo")
    end
  end
end
