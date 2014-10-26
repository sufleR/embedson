if ENV['BUILDER'] == 'travis'
  require "codeclimate-test-reporter"
  CodeClimate::TestReporter.start
else
  require 'simplecov'
  SimpleCov.start do
    add_filter '/spec/'
  end
end

require 'active_record'
require 'embedson'
require 'with_model'
require 'pry'

# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.extend WithModel

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  connection = if ENV['BUILDER'] == 'travis'
                 "postgres://postgres@localhost/travis_ci_test"
               else
                 "postgres://embedson:embedson@localhost/embedson"
               end

  ActiveRecord::Base.establish_connection(connection)

  config.order = :random
  Kernel.srand config.seed
end
