require_relative "lib/action_dispatch/testing/integration/capybara/version"

Gem::Specification.new do |spec|
  spec.name        = "action_dispatch-testing-integration-capybara"
  spec.version     = ActionDispatch::Testing::Integration::Capybara::VERSION
  spec.authors     = ["Sean Doyle"]
  spec.email       = ["sean.p.doyle24@gmail.com"]
  spec.homepage    = "https://github.com/thoughtbot/action_dispatch-testing-integration-capybara"
  spec.summary     = "Use Capybara from within ActionDispatch::IntegrationTest"
  spec.description = "Use Capybara from within ActionDispatch::IntegrationTest"
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/thoughtbot/action_dispatch-integration_test-capybara"
  spec.metadata["changelog_uri"] = "https://github.com/thoughtbot/action_dispatch-integration_test-capybara/blob/main/CHANGELOG"

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "actionpack"
  spec.add_dependency "activesupport"
  spec.add_dependency "capybara"

  spec.add_development_dependency "rspec-rails"
end
