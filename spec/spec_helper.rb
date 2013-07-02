require 'rubygems'

require 'coveralls'
Coveralls.wear!

require 'digest/sha1'
require 'net/http'
require 'yaml'

require 'rspec'
require 'rack'
require 'vcr'
require File.dirname(__FILE__) + '/../lib/multi_mail'

if RUBY_VERSION >= '1.9'
  VCR.configure do |c|
    c.cassette_library_dir = 'spec/cassettes'
    c.hook_into :faraday

    c.around_http_request do |request| # Ruby 1.9+
      VCR.use_cassette(Digest::SHA1.hexdigest(request.uri + request.body), &request)
    end
  end
end

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.expand_path("../support/**/*.rb", __FILE__)].each {|f| require f}

# Use requestb.in. Copy the content from the "Raw" tab and replace the first
# line with "HTTP/1.1 200 OK". Note that messages cannot exceed 10kb. All
# fixtures are modified to have the same Date header.
#
# Sign up for all services, and, in all cases except Cloudmailin, add an API key
# to `api_keys.yml`, which will look like:
#
#     ---
#     :mailgun_api_key:  ...
#     :mandrill_api_key: ...
#     :postmark_api_key: ...
#     :sendgrid_username: ...
#     :sendgrid_password: ...
#
# For Postmark, you must create a server to get an API key.
#
# If you see `bad content body` exceptions, run `unix2dos` on the fixtures.
#
# # Cloudmailin
#
# Change the HTTP POST format on Cloudmailin and wait a few minutes. Run
# `unix2dos` on the fixtures to fix line endings.
#
# spam.txt     Change the SPF result to "fail"
# valid.txt    Send a complex multipart message
#
# # Mailgun
#
# Run `bundle exec rake mailgun` to set up Mailgun.
#
# invalid.txt  Send a blank message and change the signature parameter value to "xxx"
# missing.txt  Send a blank message and remove the signature parameter
# spam.txt     Send a subject-less message with message body XJS*C4JDBQADN1.NSBN3*2IDNEN*GTUBE-STANDARD-ANTI-UBE-TEST-EMAIL*C.34X
# valid.txt    Send a complex multipart message, recalculate the signature parameter value for an API key of "foo"
#
# # Mandrill
#
# Run `bundle exec rake mandrill` to ensure Mandrill is properly set up.
#
# invalid.txt  Send a blank message and change the event parameter value to "xxx"
# missing.txt  Send a blank message and remove the event parameter
# spam.txt     Send a subject-less message with message body XJS*C4JDBQADN1.NSBN3*2IDNEN*GTUBE-STANDARD-ANTI-UBE-TEST-EMAIL*C.34X
# valid.txt    Send a complex multipart message
#
# # Postmark
#
# Run `bundle exec rake postmark` to set up Postmark.
#
# spam.txt     Send a subject-less message with message body XJS*C4JDBQADN1.NSBN3*2IDNEN*GTUBE-STANDARD-ANTI-UBE-TEST-EMAIL*C.34X
# valid.txt    Send a complex multipart message
#
# # SendGrid
#
# Run `bundle exec rake sendgrid` to set up SendGrid once SendGrid has
# provisioned your account.
#
# spam.txt     Send a subject-less message with message body XJS*C4JDBQADN1.NSBN3*2IDNEN*GTUBE-STANDARD-ANTI-UBE-TEST-EMAIL*C.34X
# valid.txt    Send a complex multipart message
#
# @param [String] provider a provider
# @param [String] fixture one of "valid", "invalid" or "spam"
# @param [Boolean] action_dispatch whether uploaded files should be
#   `ActionDispatch::Http::UploadedFile` objects
# @return [String] the provider's baked response
# @see FakeWeb::Responder#baked_response
# @see https://github.com/rack/rack/blob/master/test/spec_multipart.rb
def response(provider, fixture, action_dispatch = false, encoding = 'UTF-8')
  path     = File.expand_path("../fixtures/#{provider}/#{fixture}.txt", __FILE__)
  contents = File.open(path, "r:#{encoding}"){|f| f.read}
  io       = StringIO.new(contents)
  socket   = Net::BufferedIO.new(io)
  response = Net::HTTPResponse.read_new(socket)

  # `response.reading_body(socket, true) {}`, for whatever reason, fails to read
  # all of the body in files like `cloudmailin/multipart/valid.txt`.
  body = contents[/(?:\r?\n){2,}(.+)\z/m, 1]

  # It's kind of crazy that no library has an easier way of doing this.
  if response.header['x-mandrill-signature']
    body = Rack::Request.new(Rack::MockRequest.env_for('/', {
      'HTTP_X_MANDRILL_SIGNATURE' => response.header['x-mandrill-signature'],
      :method => 'POST',
      :input => body,
    }))
  elsif response.header['content-type']['multipart/form-data']
    body = Rack::Multipart.parse_multipart(Rack::MockRequest.env_for('/', {
      'CONTENT_TYPE' => response.header['content-type'],
      :input => body,
    }))
  end

  if action_dispatch
    # ActionDispatch would parse the request into a parameters hash.
    klass = Class.new(MultiMail::Service) do
      include MultiMail::Receiver::Base
    end
    normalize_encode_params(klass.parse(body))
  else
    body
  end
end

# @see https://github.com/rails/rails/blob/master/actionpack/lib/action_dispatch/http/upload.rb
class UploadedFile
  attr_accessor :original_filename, :content_type, :tempfile, :headers

  def initialize(hash)
    @original_filename = hash[:filename]
    @content_type      = hash[:type]
    @headers           = hash[:head]
    @tempfile          = hash[:tempfile]
    raise(ArgumentError, ':tempfile is required') unless @tempfile
  end

  def read(*args)
    @tempfile.read(*args)
  end
end

# @see https://github.com/rails/rails/blob/master/actionpack/lib/action_dispatch/http/parameters.rb
# @see https://github.com/rails/rails/blob/master/actionpack/lib/action_dispatch/http/upload.rb
def normalize_encode_params(params)
  if Hash === params
    if params.has_key?(:tempfile)
      UploadedFile.new(params)
    else
      new_hash = {}
      params.each do |k, v|
        new_hash[k] = case v
        when Hash
          normalize_encode_params(v)
        when Array
          v.map! {|el| normalize_encode_params(el) }
        else
          v
        end
      end
      new_hash
    end
  else
    params
  end
end

# @return [String] the path to the GIF file
def empty_gif_path
  File.expand_path('../fixtures/empty.gif', __FILE__)
end

# @return [String] the content of the GIF file
def empty_gif_content
  File.read(empty_gif_path)
end
