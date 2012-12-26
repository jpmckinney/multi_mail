require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe MultiMail::Receiver do
  describe '#new' do
    it 'should not raise an error if the provider is recognized' do
      expect{ MultiMail::Receiver.new :provider => :mailgun, :mailgun_api_key => 1 }.to_not raise_error
    end

    it 'should raise an error if the provider is not recognized' do
      expect{ MultiMail::Receiver.new :provider => :foo }.to raise_error(ArgumentError)
    end
  end
end
