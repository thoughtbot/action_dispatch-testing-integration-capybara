require "action_dispatch/testing/integration/capybara"

ActiveSupport.on_load :action_dispatch_integration_test do
  require "capybara/minitest"

  include ::Capybara::Minitest::Assertions
end
