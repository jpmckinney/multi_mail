require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe MultiMail do
  describe '#new' do
    it 'should raise an error if the provider is not recognized' do
      expect{ MultiMail.new :provider => 'foo' }.to raise_error(ArgumentError)
    end
  end
end
