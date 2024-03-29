require "test_helper"
require "action_dispatch/testing/integration/capybara/minitest"

class ActionDispatch::Testing::Integration::CapybaraTest < ActionDispatch::IntegrationTest
  test "supports Capybara assertions" do
    post templates_path, params: { template: <<~HTML }
      <button>A button</button>
    HTML

    assert_button "A button"
  end

  test "clears page across multiple requests" do
    post templates_path, params: { template: <<~HTML }
      <button>Request 1</button>
    HTML

    assert_button "Request 1"

    post templates_path, params: { template: <<~HTML }
      <button>Request 2</button>
    HTML

    assert_button "Request 2"
  end

  test "supports Capybara::Session#within" do
    post templates_path, params: { template: <<~HTML }
      <section><h1>Hello, World!</h1></section>
    HTML

    within("section") { assert_text "Hello, World!" }
  end
end
