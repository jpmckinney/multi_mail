require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

task :default => :spec

begin
  require 'yard'
  YARD::Rake::YardocTask.new
rescue LoadError
  task :yard do
    abort 'YARD is not available. In order to run yard, you must: gem install yard'
  end
end

require 'yaml'

def credentials
  @credentials ||= YAML.load_file File.expand_path(File.join(File.dirname(__FILE__), 'api_keys.yml'))
end

desc 'Create a Mailgun catch-all route forwarding to a postbin'
task :mailgun do
  require 'securerandom'
  require 'json'
  require 'rest-client'

  def bin_url_and_action
    bin_name = JSON.load(RestClient.post('http://requestb.in/api/v1/bins', {}))['name']
    ["http://requestb.in/#{bin_name}", %(forward("#{bin_url}"))]
  end

  base_url = "https://api:#{credentials[:mailgun_api_key]}@api.mailgun.net/v2"
  domain = JSON.load(RestClient.get("#{base_url}/domains"))['items'].first

  if domain
    domain_name = domain['name']
  else
    domain_name = "#{SecureRandom.base64(4).tr('+/=lIO0', 'pqrsxyz')}.mailgun.com"
    puts "Creating the #{domain_name} domain..."
    RestClient.post("#{base_url}/domains", :name => domain_name)
  end

  catch_all_route = JSON.load(RestClient.get("#{base_url}/routes"))['items'].find do |route|
    route['expression'] == 'catch_all()'
  end

  if catch_all_route
    bin_url, action = bin_url_and_action
    puts "Updating the catch_all() route..."
    JSON.load(RestClient.put("#{base_url}/routes/#{catch_all_route['id']}", :action => action))
  else
    bin_url, action = bin_url_and_action
    puts "Creating a catch_all() route..."
    JSON.load(RestClient.post("#{base_url}/routes", :expression => 'catch_all()', :action => action))
  end

  puts "The catchall route for #{domain_name} POSTs to #{bin_url}?inspect"
end

desc 'Ensure a Mandrill catch-all route forwarding to a postbin'
task :mandrill do
  require 'mandrill'

  api = Mandrill::API.new(credentials[:mandrill_api_key])
  domain = api.inbound.domains.first

  if domain
    domain_name = domain['domain']
    routes = api.inbound.routes(domain_name)
    match = routes.find{|route| route['pattern'] == '*'}

    puts "The MX for #{domain_name} is not valid" unless domain['valid_mx']
    puts "Add a catchall (*) route for #{domain_name}" if match.nil?
    puts "The catchall route for #{domain_name} POSTs to #{match['url']}?inspect"
  else
    abort 'Add an inbound domain at https://mandrillapp.com/ or, if you already have your MX records set up, by sending an email through Mandrill'
  end
end

desc 'Create a Postmark route forwarding to a postbin'
task :postmark do
  require 'json'
  require 'postmark'
  require 'rest-client'

  api = Postmark::ApiClient.new(credentials[:postmark_api_key])
  info = api.server_info

  bin_name = JSON.load(RestClient.post('http://requestb.in/api/v1/bins', {}))['name']
  url = "http://requestb.in/#{bin_name}"
  puts "Setting the POST URL..."
  api.update_server_info :inbound_hook_url => url

  puts "#{info[:inbound_hash]}@inbound.postmarkapp.com POSTs to #{url}?inspect"
end

desc 'Create a SendGrid route forwarding to a postbin'
task :sendgrid do
  require 'json'
  require 'rest-client'
  require 'sendgrid_webapi'

  api = SendGridWebApi::Client.new(credentials[:sendgrid_username], credentials[:sendgrid_password])
  routes = api.parse_email.get['parse']

  if routes.empty? && ENV['DOMAIN'].nil?
    abort 'usage: DOMAIN=example.com bundle exec rake sendgrid'
  end

  domain_name = if routes.any?
    routes.first['hostname']
  else
    ENV['DOMAIN']
  end

  bin_name = JSON.load(RestClient.post('http://requestb.in/api/v1/bins', {}))['name']
  url = "http://requestb.in/#{bin_name}"
  puts "Setting the POST URL..."
  result = api.parse_email.set(hostname: domain_name, url: url, spam_check: 0)

  if result['error']
    puts "HTTP #{result['error']['code']} #{result['error']['message']}"
  else
    puts "#{domain_name} POSTs to #{url}?inspect"
  end
end

desc 'POST a test fixture to an URL'
task :http_post, :url, :fixture do |t,args|
  require 'rest-client'

  contents = File.read(args[:fixture])
  io       = StringIO.new(contents)
  socket   = Net::BufferedIO.new(io)
  response = Net::HTTPResponse.read_new(socket)
  body = contents[/(?:\r?\n){2,}(.+)\z/m, 1]

  puts RestClient.post(args[:url], body, :content_type => response.header['content-type'])
end
