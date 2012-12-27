require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MultiMail::Service do
  module MultiMail
    module Sender
      class Mock < MultiMail::Service
      end
    end
  end
end
