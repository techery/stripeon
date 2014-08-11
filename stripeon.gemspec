$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "stripeon/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'stripeon'
  s.version     = Stripeon::VERSION
  s.authors     = ['Sergey Stupachenko', 'Michael Kurtikov']
  s.email       = ["hello@techery.io"]
  s.homepage    = 'https://github.com/techery/stripeon'
  s.summary     = 'Flexible subscription solution for Rails with Stripe'
  s.description = 'Flexible subscription solution for Rails with Stripe'
  s.license     = 'MIT'

  s.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.rdoc']
  s.test_files = Dir['spec/**/*']

  s.add_dependency 'rails',                     '~> 4.1.4'
  s.add_dependency 'stripe',                    '~> 1.10.1'
  s.add_dependency 'state_machine',             '~> 1.2.0'
  s.add_dependency 'state_machine-audit_trail', '~> 0.1.8'
  s.add_dependency 'prawn',                     '~> 0.14.0'
  s.add_dependency 'draper',                    '~> 1.3'
  s.add_dependency 'sidekiq',                   '~> 2.17.4'

  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'rspec-rails',        '~> 3.0.1'
  s.add_development_dependency 'factory_girl_rails', '~> 4.3.0'
  s.add_development_dependency 'shoulda-matchers',   '~> 2.6.1'
  s.add_development_dependency 'capybara',           '~> 2.2.1'
  s.add_development_dependency 'capybara-webkit',    '~> 1.1.0'
  s.add_development_dependency 'ffaker',             '~> 1.23.0'
end
