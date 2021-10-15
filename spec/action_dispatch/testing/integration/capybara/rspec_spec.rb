require "rails_helper"
require "action_dispatch/testing/integration/capybara/rspec"

RSpec.describe "Capybara extensions", type: :request do
  it "supports Capybara matchers" do
    post templates_path, params: { template: <<~HTML }
      <button>A button</button>
    HTML

    expect(page).to have_button "A button"
  end

  it "supports Capybara::Session#within" do
    post templates_path, params: { template: <<~HTML }
      <section><h1>Hello, World!</h1></section>
    HTML

    within("section") { expect(page).to have_text "Hello, World!" }
  end
end
