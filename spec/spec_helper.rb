require 'net/http'
require 'yaml'

require 'rubygems'
require 'rspec'
require File.dirname(__FILE__) + '/../lib/multi_mail'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.expand_path("../support/**/*.rb", __FILE__)].each {|f| require f}

# @return [Hash] required arguments to initialize services
def credentials
  @credentials ||= YAML.load_file(File.expand_path('../../api_keys.yml', __FILE__))
end

# @param [String] provider a provider
# @param [String] fixture one of "valid", "invalid" or "spam"
# @return [String] the provider's baked response
# @see FakeWeb::Responder#baked_response
def response(provider, fixture)
  io       = File.open(File.expand_path("../fixtures/#{provider}/#{fixture}.txt", __FILE__), 'r')
  socket   = Net::BufferedIO.new(io)
  response = Net::HTTPResponse.read_new(socket)
  response.reading_body(socket, true) {}
end
