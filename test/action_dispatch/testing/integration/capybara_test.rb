require "test_helper"

class ActionDispatch::Testing::Integration::CapybaraTest < ActiveSupport::TestCase
  test "it has a version number" do
    assert ActionDispatch::Testing::Integration::Capybara::VERSION
  end
end
