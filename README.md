# ActionDispatch::Testing::Integration::Capybara

Use [Capybara][] from within [ActionDispatch::IntegrationTest][].

## Why?

If your application relies on your server to generate and transmit _all_ of its
<abbr title="Hypertext Markup Language">HTML</abbr>, then the structure and
contents of those <abbr title="Hypertext Transfer Protocol">HTTP</abbr> requests
and responses is **crucial**.

Testing the overlap between Controllers and Views
---

Out of the box, Action Dispatch depends on the [rails-dom-testing][] gem to
provide tests with a way of asserting the structure and contents of a request's
HTML response body. For example, consider an HTML response for an HTTP [GET][]
request to `/articles/hello-world`:

```html
<html>
  <head>
    <title>Hello, World!</title>
  </head>
  <body>
    <main>
      <h1>Hello, World!</h1>
    </main>
  </body>
</html>
```

The `rails-dom-testing` gem provides a collection of methods that transform [CSS
selectors][] and text into assertions about the structure and contents of the
response body's HTML:

```ruby
class ArticlesTest < ActionDispatch::IntegrationTest
  test "index" do
    get article_path("hello-world")

    assert_select "title", "Hello, World!"
    assert_select "body main h1", "Hello, World!"
  end
end
```

In their most simple form, they provide a lot of utility in their flexibility.
In spite of that flexibility, writing assertions in this style can become
complicated in the face of _Real World features_.

For example, consider an HTML response for an HTTP [GET][] request to
`/sessions/new`:

```html
<html>
  <head>
    <title>Sign in</title>
  </head>
  <body>
    <main>
      <h1>Sign in</h1>

      <form method="post" action="/sessions">
        <label for="session_email_address">Email address</label>
        <input type="email" id="session_email_address" name="session[email_address]">

        <label for="session_password">Password</label>
        <input type="password" id="session_password" name="session[password]">

        <button>Sign in</button>
      </form>
    </main>
  </body>
</html>
```

The `ActionDispatch::IntegrationTest` cases for this page might cover several
facets of the HTML, namely:

1. The page has a `<title>` element containing the text `"Sign in"`
2. The page has the text `"Sign in"` in its header _and_ a `<button>` with
   `"Sign in"` as its content, and that they're _two different_ elements.
3. The page has an `<input type="email">` element to collect the user's email
   address, and [that field is labelled][] with the text `"Email address"`
4. The page has an `<input type="password">` element to collect the user's
   password, and [that field is labelled][] with the text `"Password"`.

We could cover those requirements with the following `rails-dom-testing`-capable
test:

```ruby
class SessionsTest < ActionDispatch::IntegrationTest
  test "new" do
    get new_session_path

    assert_select "title", "Sign in"
    assert_select "body main h1", "Sign in"
    assert_select "body main button", "Sign in"
    assert_select %(input[id="session_email_address"][type="email"])
    assert_select %(label[for="session_email_address"]), "Email address"
    assert_select %(input[id="session_password"][type="password"])
    assert_select %(label[for="session_password"]), "Password"
  end
end
```

These assertions are sufficient to exercise the page, making sure it meets all
of our requirements. Unfortunately, the assertions have some issues.

For instance, the assertions about the relationships between the `<input>` and
`<label>` elements are extremely brittle. They encode the
`session_email_address` and `session_password` element `[id]` attribute directly
into the test. If that page's HTML were to change, those tests would fail even
if the new HTML declared the `<label>` elements with the same text content and
in a way that continued to properly reference their `<input>` elements.

Similarly, the specificity required by the `title`, `h1`, and `button` selectors
is tedious compared to how different a `<title>`, `<h1>` and `<button>` are
treated by a browser.

These types of issues could be addressed by introducing abstractions
to account for the varying semantics of each requirement. Luckily, a tool that
already does that on our behalf exists: System Tests!

If we were to write a System Test to exercise our page to make sure it meets the
requirements, it might resemble something like:

```ruby
class SessionsTest < ActionDispatch::SystemTestCase
  test "new" do
    visit new_session_path

    assert_title "Sign in"
    assert_css "h1", "Sign in"
    assert_button "Sign in"
    assert_field "Email address", type: "email"
    assert_field "Password", type: "password"
  end
end
```

These assertions are not only more terse, they're also more robust. For example,
the `assert_button` will continue to pass if the `<button>` element were
replaced with an `<input type="submit">` element with the same text. Similarly,
the `assert_field` calls would continue to pass if the `<input>` elements `[id]`
attributes were changed, or if they were moved to be direct descendants of the
`<label>` element. What an improvement!

Unfortunately, these improvements come with a cost.

[that field is labelled]: https://developer.mozilla.org/en-US/docs/Web/Accessibility/Understanding_WCAG/Text_labels_and_names#form_elements_must_be_labeled

The Challenges of a growing test suite
---

In practice, a Rails application's test suite will exercise its controller and
view code in **two** ways: through [ActionDispatch::IntegrationTest][] tests,
and through [ActionDispatch::SystemTestCase][] tests.

[System Tests][] are often executed by driving **real** browsers with tools like
[Selenium][], [Webdriver][], or over the [Chrome DevTools Protocol][] (via
[apparition][]). The good news: driving a browser through your test cases
provides _an extremely high_ and valuable level of fidelity and confidence in
the end-user experience. The bad news: driving a browser through your test
incurs _an extremely high_ cost: speed.

That cost can be recuperated by configuring System Tests to be [`driven_by
:rack_test`][]. When configured this way, test cases rely on a Rack Test
"browser" to make HTTP requests, "click" on buttons, and "fill in" form fields
on their behalf. These types of tests are valuable in their own right, but they
don't provide the same level on control as `ActionDispatch::IntegrationTest`
cases.

For example, an `ActionDispatch::IntegrationTest` can submit an HTTP request
with any [HTTP verb][], whereas a System Test can only directly submit `GET`
requests through calls to [visit][]. Similarly, System Tests can't access the
response's [status code][] or its [headers][] directly, nor can it read from
Rails-specific utilities like the [`cookies`, `flash`, or `session`][]. For
example, consider a test that exercises a controller's response to an invalid
request:

```ruby
class ArticlesTest < ActionDispatch::IntegrationTest
  test "update" do
    valid_attributes    = { title: "A valid Article", body: "It's valid!" }
    invalid_attributes  = { title: "Will be invalid", body: "" }
    article             = Article.create! valid_attributes

    assert_no_changes -> { article.reload.attributes } do
      put article_path(article), params: { article: invalid_attributes }
    end

    assert_response :unprocessable_entity
    assert_equal "Failed to create Article!", flash[:alert]
  end
end
```

Conversely, `ActionDispatch::IntegrationTest` cases exercise the application one
layer of abstraction below the browser: at the HTTP request-response layer. They
don't drive a **real** browser, but they do make the same kinds of HTTP
requests! On top of that, they provide built-in mechanisms to read directly from
the response, session, flash, or cookies.

It can be challenging to strike a balance between the confidence & fidelity of
System Tests and the speed and granularity of Integration Tests when exercising
the structure and contents of a feature's HTML. It can be even more challenging
if you need to maintain and context switch between two parallel sets of HTML
assertions. Since both System Tests and Integration Tests are Rack
Test-compliant, wouldn't it be nice if there was a way to get the best of both
worlds?

Combining `ActionDispatch::IntegrationTest` with `Capybara`
---

[Capybara][] provides Rails' System Tests with its collection of finders,
actions, and assertions. Conceptually, the value provided by Capybara's finders
and assertions overlaps entirely with the assertions provided by
`rails-dom-testing`. If we wanted to share the same `Rack::Test` session between
our `ActionDispatch::IntegrationTest` case and our `Capybara` assertions, we'd
need to integrate a `Capybara::Session` instance with the
[`integration_session`][] at the heart of our tests. If we wanted to modify the
`ActionDispatch::IntegrationTest` class, we could do so with an
[ActiveSupport::Concern][] mixed-into the class from within an
[`ActiveSupport.on_load`] hook:

```ruby
ActiveSupport.on_load :action_dispatch_integration_test do
  include(Module.new do
    extend ActiveSupport::Concern

    included do
      setup do
        integration_session.extend(Module.new do
          # ...
        end)
      end
    end
  end)
end
```

Within that concern, we'd want to declare a `#page` method like the one our
System Tests provide. Within the `#page` method, we'd construct, memoize, and
return an instance of a `Capybara::Session`:

```diff
 ActiveSupport.on_load :action_dispatch_integration_test do
   include(Module.new do
     extend ActiveSupport::Concern

     included do
       setup do
         integration_session.extend(Module.new do
+          def page
+            @page ||= ::Capybara::Session.new(:rack_test, @app)
+          end
         end)
       end
     end
   end)
 end
```

Once we constructed that instance, we'd need to make it available to the
inner-working mechanics of the `ActionDispatch::IntegrationTest` case. Right
now, the only avenue toward that goal is re-declaring the [`_mock_session`][]
private method:

```diff
 ActiveSupport.on_load :action_dispatch_integration_test do
   include(Module.new do
     extend ActiveSupport::Concern

     included do
       setup do
         integration_session.extend(Module.new do
           def page
             @page ||= ::Capybara::Session.new(:rack_test, @app)
           end
+
+          def _mock_session
+            @_mock_session ||= page.driver.browser.rack_mock_session
+          end
         end)
       end
     end
   end)
 end
```

Depending on Rails' private interfaces is _very_ risky and _highly_ discouraged.
There is an ongoing discussion about adding public-facing hooks for this type of
integration (see [rails/rails#41291][] and [rails/rails#43361][]). Since these a
test-level dependencies, changes to the private implementation won't lead to
production-level outages. Ideally, this will only be temporary!

With those changes in place, the last step is to mix-in Capybara's assertions:

```diff
+require "capybara/minitest"
+
 ActiveSupport.on_load :action_dispatch_integration_test do
   include(Module.new do
     extend ActiveSupport::Concern

     included do
+      include Capybara::Minitest::Assertions
+
       setup do
         integration_session.extend(Module.new do
           def page
             @page ||= ::Capybara::Session.new(:rack_test, @app)
           end

           def _mock_session
             @_mock_session ||= page.driver.browser.rack_mock_session
           end
         end)
       end
     end
   end)
 end
```

Now we can re-write our `SessionsTest` to inherit from
`ActionDispatch::IntegrationTest` instead of `ActionDispatch::SystemTestCase`:

```diff
-class SessionsTest < ActionDispatch::SystemTestCase
+class SessionsTest < ActionDispatch::IntegrationTest
   test "new" do
-    visit new_session_path
+    get new_session_path

     assert_title "Sign in"
     assert_css "h1", "Sign in"
     assert_button "Sign in"
     assert_field "Email address", type: "email"
     assert_field "Password", type: "password"
   end
 end
```

If we wanted to use other Capybara-provided helpers like [within][], we could
delegate those calls to our `page` instance:

```diff
 require "capybara/minitest"

 ActiveSupport.on_load :action_dispatch_integration_test do
   include(Module.new do
     extend ActiveSupport::Concern

     included do
       include Capybara::Minitest::Assertions
+
+      delegate :within, to: :page

       setup do
         integration_session.extend(Module.new do
           def page
             @page ||= ::Capybara::Session.new(:rack_test, @app)
           end

           def _mock_session
             @_mock_session ||= page.driver.browser.rack_mock_session
           end
         end)
       end
     end
   end)
 end
```

Then we could use them in our tests:

```diff
 class SessionsTest < ActionDispatch::IntegrationTest
   test "new" do
     get new_session_path

     assert_title "Sign in"
+    within "main" do
       assert_css "h1", "Sign in"
       assert_button "Sign in"
       assert_field "Email address", type: "email"
       assert_field "Password", type: "password"
+    end
   end
 end
```

With this integration in place, there's nothing stopping us from [declaring
custom Capybara selectors][], or adding a dependency like
[`citizensadvice/capybara_accessible_selectors`][] that declares them on our
behalf:

```diff
 class SessionsTest < ActionDispatch::IntegrationTest
   test "new" do
     get new_session_path

     assert_title "Sign in"
-    within "main" do
+    within_section "Sign in" do
-      assert_css "h1", "Sign in"
       assert_button "Sign in"
       assert_field "Email address", type: "email"
       assert_field "Password", type: "password"
     end
   end
 end
```

With access to assertions and selectors like the ones that Capybara or
[`citizensadvice/capybara_accessible_selectors`][] provide (like
[assert_field][], the [described_by:][] filter, and the [alert][] selector), we
have an opportunity to make assertions about the structure _and_ semantics of
the response to an invalid request:

```diff
 class ArticlesTest < ActionDispatch::IntegrationTest
   test "update" do
     valid_attributes    = { title: "A valid Article", body: "It's valid!" }
     invalid_attributes  = { title: "Will be invalid", body: "" }
     article             = Article.create! valid_attributes

     assert_no_changes -> { article.reload.attributes } do
       put article_path(article), params: { article: invalid_attributes }
     end

     assert_response :unprocessable_entity
-    assert_equal "Failed to create Article!", flash[:alert]
+    assert_selector :alert, "Failed to create Article!"
+    assert_field "Body", described_by: "can't be blank"
   end
 end
```

[assert_field]: https://www.rubydoc.info/github/jnicklas/capybara/Capybara/Minitest/Assertions#assert_field-instance_method
[described_by:]: https://github.com/citizensadvice/capybara_accessible_selectors/tree/v0.4.2#described_by-string
[alert]: https://github.com/citizensadvice/capybara_accessible_selectors/tree/v0.4.2#alert

Hopefully, an integration like this will become publicly supported in the
future. In the meantime, if you'd like to add support for Capybara assertions in
your Minitest suite's `ActionDispatch::IntegrationTest` cases, or your RSpec
suite's `type: :request` tests, check out the
[`thoughtbot/action_dispatch-testing-integration-capybara`][] gem today!

[rails-dom-testing]: https://github.com/rails/rails-dom-testing#railsdomtesting
[GET]: https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods/GET
[CSS selectors]: https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Selectors
[ActionDispatch::IntegrationTest]: https://edgeapi.rubyonrails.org/classes/ActionDispatch/IntegrationTest.html
[ActionDispatch::SystemTestCase]: https://edgeapi.rubyonrails.org/classes/ActionDispatch/SystemTestCase.html
[System Tests]: https://guides.rubyonrails.org/testing.html#system-testing
[Selenium]: https://www.selenium.dev
[Webdriver]: https://developer.mozilla.org/en-US/docs/Web/WebDriver
[Chrome DevTools Protocol]: https://chromedevtools.github.io/devtools-protocol/
[apparition]: https://github.com/twalpole/apparition
[`driven_by :rack_test`]: https://edgeapi.rubyonrails.org/classes/ActionDispatch/SystemTestCase.html#method-c-driven_by
[HTTP verb]: https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods
[visit]: https://rubydoc.info/github/teamcapybara/capybara/master/Capybara/Session#visit-instance_method
[status code]: https://developer.mozilla.org/en-US/docs/Web/HTTP/Status
[headers]: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers
[`cookies`, `flash`, or `session`]: https://guides.rubyonrails.org/testing.html#the-three-hashes-of-the-apocalypse
[Capybara]: http://teamcapybara.github.io/capybara/
[`integration_session`]: https://edgeapi.rubyonrails.org/classes/ActionDispatch/Integration/Runner.html#method-i-integration_session
[ActiveSupport::Concern]: https://edgeapi.rubyonrails.org/classes/ActiveSupport/Concern.html
[`ActiveSupport.on_load`]: https://guides.rubyonrails.org/engines.html#available-load-hooks
[`_mock_session`]: https://github.com/rails/rails/blob/v7.0.0.alpha2/actionpack/lib/action_dispatch/testing/integration.rb#L300
[rails/rails#41291]: https://github.com/rails/rails/pull/41291
[rails/rails#43361]: https://github.com/rails/rails/pull/43361
[within]: https://rubydoc.info/github/teamcapybara/capybara/master/Capybara/Session#within-instance_method
[declaring custom Capybara selectors]: https://github.com/teamcapybara/capybara#xpath-css-and-selectors
[`citizensadvice/capybara_accessible_selectors`]: https://github.com/citizensadvice/capybara_accessible_selectors#documentation
[`thoughtbot/action_dispatch-testing-integration-capybara`]: https://github.com/thoughtbot/action_dispatch-testing-integration-capybara

## Installation

This gem re-opens existing Action Dispatch-provided classes. That fact is
reflected in the gem's name. Since the name is dependent on the structure of the
`action_dispatch/` directory within the `action_pack` gem, and that gem is part
of Rails' core suite of packages, this project _will not_ be published to
Rubygems in its current form.

There is an on-going discussion (see [rails/rails#41291][] and
[rails/rails#43361][]) about building this behavior into Rails itself. Until
that discussion concludes, this gem will serve as a temporary solution.

To reflect the temporary nature of this project, `Gemfile` entries should refer
to the GitHub URL and release tags with the `github:` and `tag:` options.

Install with `minitest`
---

To use the gem with `minitest`, add the following entry, making sure to declare
`require: "action_dispatch/testing/integration/capybara/minitest"`:

```ruby
gem "action_dispatch-testing-integration-capybara",
  github: "thoughtbot/action_dispatch-testing-integration-capybara", tag: "v0.1.0",
  require: "action_dispatch/testing/integration/capybara/minitest"
```

And then execute:
```bash
$ bundle
```

Install with `rspec`
---

To use the gem with `rspec`, add the following entry, making sure to declare
`require: "action_dispatch/testing/integration/capybara/rspec"`:

```ruby
gem "action_dispatch-testing-integration-capybara",
  github: "thoughtbot/action_dispatch-testing-integration-capybara", tag: "v0.1.0",
  require: "action_dispatch/testing/integration/capybara/rspec"
```

And then execute:
```bash
$ bundle
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## About

This project is maintained by Sean Doyle.

![thoughtbot](http://presskit.thoughtbot.com/images/thoughtbot-logo-for-readmes.svg)

This project is maintained and funded by thoughtbot, inc.
The names and logos for thoughtbot are trademarks of thoughtbot, inc.

We love open source software!
See [our other projects][community]
or [hire us][hire] to help build your product.

[community]: https://thoughtbot.com/community?utm_source=github
[hire]: https://thoughtbot.com/hire-us?utm_source=github
