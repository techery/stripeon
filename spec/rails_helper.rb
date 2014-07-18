ENV["RAILS_ENV"] ||= 'test'

require 'spec_helper'
require File.expand_path('../dummy/config/environment', __FILE__)
require 'rspec/rails'
require 'capybara/rails'
require 'capybara/rspec'
require 'capybara/webkit'
require 'capybara-screenshot/rspec'
require 'shoulda/matchers'
require 'factory_girl_rails'
require 'ffaker'
require 'database_cleaner'

Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

ActiveRecord::Migration.maintain_test_schema!

Capybara.javascript_driver = :webkit
Capybara.default_wait_time = 10

RSpec.configure do |config|
  config.use_transactional_fixtures =  false
  config.infer_spec_type_from_file_location!

  config.include Warden::Test::Helpers, type: :feature

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)

    Warden.test_mode!
  end

  config.before(:each) do
    config.use_transactional_fixtures = true
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, :js => true) do
    config.use_transactional_fixtures = false
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
    Warden.test_reset!
  end
end
