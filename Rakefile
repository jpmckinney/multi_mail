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

namespace :postbin do
  require 'json'
  require 'yaml'

  require 'rest-client'

  def credentials
    @credentials ||= YAML.load_file File.expand_path(File.join(File.dirname(__FILE__), 'api_keys.yml'))
  end

  desc 'Create a Mailgun catch-all route forwarding to a postbin'
  task :mailgun do
    bin_name = ENV['BIN_NAME'] || JSON.load(RestClient.post('http://requestb.in/api/v1/bins', {}))['name']
    bin_url  = "http://requestb.in/#{bin_name}"

    base_url = "https://api:#{credentials[:mailgun_api_key]}@api.mailgun.net/v2/routes"
    action   = %(forward("#{bin_url}"))

    route = JSON.load(RestClient.get(base_url))['items'].find do |route|
      route['expression'] == 'catch_all()'
    end

    if route
      unless route['action'] == action
        JSON.load(RestClient.put("#{base_url}/#{route['id']}", :action => action))
      end
    else
      JSON.load(RestClient.post(base_url, :expression => 'catch_all()', :action => action))
    end

    puts "#{bin_url}?inspect"
  end
end
