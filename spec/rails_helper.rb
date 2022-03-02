require 'spec_helper'

ENV['RAILS_ENV'] ||= 'test'
abort("The Rails environment is running in production mode!") if Rails.env.production?

require 'rspec/rails'
require 'factory_bot_rails'

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end


RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_base_class_for_anonymous_controllers = false
  config.order = "random"
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
  config.include FactoryBot::Syntax::Methods
  config.render_views
end