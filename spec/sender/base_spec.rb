require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MultiMail::Sender::Base do
  let :klass do
    Class.new(MultiMail::Service) do
      include MultiMail::Sender::Base

      def valid?(params)
        params['foo'] == 1
      end

      def transform(params)
        [Mail.new]
      end
    end
  end

  let :service do
    klass.new
  end
end
