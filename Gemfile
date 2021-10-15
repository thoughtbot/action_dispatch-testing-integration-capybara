source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Specify your gem's dependencies in action_dispatch-testing-integration-capybara.gemspec.
gemspec

gem "sprockets-rails"

case (rails_version = ENV.fetch("RAILS_VERSION", "main"))
when "main"
  gem "rails", github: "rails/rails"
else
  gem "rails", "~>#{rails_version}.0"
end

# Start debugger with binding.b -- Read more: https://github.com/ruby/debug
# gem "debug", ">= 1.0.0", group: %i[ development test ]
