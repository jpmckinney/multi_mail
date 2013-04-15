require 'net/http'
require 'yaml'

require 'rubygems'
require 'rspec'
require 'rack'
require File.dirname(__FILE__) + '/../lib/multi_mail'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.expand_path("../support/**/*.rb", __FILE__)].each {|f| require f}

# @param [String] provider a provider
# @param [String] fixture one of "valid", "invalid" or "spam"
# @return [String] the provider's baked response
# @see FakeWeb::Responder#baked_response
# @see https://github.com/rack/rack/blob/master/test/spec_multipart.rb
def response(provider, fixture)
  io       = StringIO.new(File.read(File.expand_path("../fixtures/#{provider}/#{fixture}.txt", __FILE__)))
  socket   = Net::BufferedIO.new(io)
  response = Net::HTTPResponse.read_new(socket)
  body     = response.reading_body(socket, true) {}
  # The above method seems sensitive to buffer/file sizes.

  if response.header['content-type']['multipart/form-data']
    Rack::Multipart.parse_multipart(Rack::MockRequest.env_for('/', {
      'CONTENT_TYPE' => response.header['content-type'],
      :input => body,
    }))
  else
    body
  end
end
