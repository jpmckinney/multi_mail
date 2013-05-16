# -*- encoding: utf-8 -*-
require File.expand_path('../lib/multi_mail/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = "multi_mail"
  s.version     = MultiMail::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Open North"]
  s.email       = ["info@opennorth.ca"]
  s.homepage    = "http://github.com/opennorth/multi_mail"
  s.summary     = %q{Easily switch between email APIs}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'mail', '~> 2.5.3' # Rails 3.2.13, less buggy than 2.4.x
  s.add_runtime_dependency 'multimap', '~> 1.1.2'
  s.add_runtime_dependency 'rack', '~> 1.4'

  # For testing
  s.add_development_dependency 'coveralls'
  s.add_development_dependency 'json', '~> 1.7.7' # to silence coveralls warning
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '~> 2.10'

  # For Rake tasks
  s.add_development_dependency 'mandrill-api', '~> 1.0.12'
  s.add_development_dependency 'postmark'
  s.add_development_dependency 'rest-client', '~> 1.6.7'
end
