# -*- encoding: utf-8 -*-
require File.expand_path('../lib/multi_mail/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = "multi_mail"
  s.version     = MultiMail::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["James McKinney"]
  s.homepage    = "https://github.com/jpmckinney/multi_mail"
  s.summary     = %q{Easily switch between email APIs}
  s.license     = 'MIT'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency('faraday', '~> 0.9.0')
  s.add_runtime_dependency('mail', '~> 2.5')
  s.add_runtime_dependency('rack')

  # For testing
  s.add_development_dependency('actionmailer', '~> 4.2.1')
  s.add_development_dependency('coveralls')
  s.add_development_dependency('rake')
  s.add_development_dependency('rspec', '~> 2.10')

  # For Rake tasks
  s.add_development_dependency('mandrill-api', '~> 1.0.35')
  s.add_development_dependency('postmark')
  s.add_development_dependency('rest-client', '~> 1.8.0')
  # sendgrid_webapi 0.0.2 depends on Faraday 0.8.
  # s.add_development_dependency('sendgrid_webapi', '0.0.2')
end
