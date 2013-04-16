require 'net/http'
require 'yaml'

require 'rubygems'
require 'rspec'
require 'rack'
require File.dirname(__FILE__) + '/../lib/multi_mail'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.expand_path("../support/**/*.rb", __FILE__)].each {|f| require f}

# Use requestb.in. Copy the content from the "Raw" tab and replace the first
# line with "HTTP/1.1 200 OK". Note that messages cannot exceed 10kb.
#
# # Cloudmailin
#
# Change the HTTP POST format on Cloudmailin and wait a few minutes. Run
# `unix2dos` on the fixtures to fix line endings.
#
# valid.txt    Send a complex multipart message
# spam.txt     Change the SPF result to "fail"
#
# # Mailgun
#
# Run `bundle exec rake mailgun`
#
# invalid.txt  Send a blank message and change the signature parameter value to "xxx"
# missing.txt  Send a blank message and remove the signature parameter
# spam.txt     Send a subject-less message with message body XJS*C4JDBQADN1.NSBN3*2IDNEN*GTUBE-STANDARD-ANTI-UBE-TEST-EMAIL*C.34X
# valid.txt    Send a complex multipart message, recalculate the signature parameter value for an API key of "foo"
#
# # Mandrill
#
# Run `bundle exec rake mandrill`
#
# invalid.txt  Send a blank message and change the event parameter value to "xxx"
# missing.txt  Send a blank message and remove the event parameter
# spam.txt     Send a subject-less message with message body XJS*C4JDBQADN1.NSBN3*2IDNEN*GTUBE-STANDARD-ANTI-UBE-TEST-EMAIL*C.34X
# valid.txt    Send a complex multipart message
#
# @param [String] provider a provider
# @param [String] fixture one of "valid", "invalid" or "spam"
# @return [String] the provider's baked response
# @see FakeWeb::Responder#baked_response
# @see https://github.com/rack/rack/blob/master/test/spec_multipart.rb
def response(provider, fixture)
  contents = File.read(File.expand_path("../fixtures/#{provider}/#{fixture}.txt", __FILE__))
  io       = StringIO.new(contents)
  socket   = Net::BufferedIO.new(io)
  response = Net::HTTPResponse.read_new(socket)
  # `response.reading_body(socket, true) {}`, for whatever reason, fails to read
  # all of the body in files like `cloudmailin/multipart/valid.txt`.
  body = contents[/(?:\r?\n){2,}(.+)\z/m, 1]

  if response.header['content-type']['multipart/form-data']
    Rack::Multipart.parse_multipart(Rack::MockRequest.env_for('/', {
      'CONTENT_TYPE' => response.header['content-type'],
      :input => body,
    }))
  else
    body
  end
end
