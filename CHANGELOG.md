# Changelog

The noteworthy changes for each `ActionDispatch::Testing::Integration::Capybara`
version are included here. For a complete changelog, see the [commits] for each
version via the version links.

[commits]: https://github.com/thoughtbot/action_dispatch-testing-integration-capybara/commits/main

## main

*   Expand CI matrix to include newer Rails versions: `7.2`, `8.0`, `8.1`

    *Sean Doyle*

*   Expand CI matrix to include newer Ruby versions: `3.3`, `3.4`

    *Sean Doyle*

*   Drop support for end-of-life Rails versions: `6.0`, `6.1`, `7.0`

    *Sean Doyle*

*   Drop support for end-of-life Ruby versions: `2.7`, `3.0`, `3.1`

    *Sean Doyle*

## 0.1.1 (Jan 26, 2023)

*   Invoke [Capybara::RackTest::Browser#reset_cache!](https://github.com/teamcapybara/capybara/blob/master/lib/capybara/rack_test/browser.rb#L112-L114) while issuing multiple requests

    *Sean Doyle*
