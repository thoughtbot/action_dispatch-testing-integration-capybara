require "action_dispatch/testing/integration"
require "active_support/concern"
require "capybara"

module ActionDispatch
  module Testing
    module Integration
      module Capybara
        class Railtie < ::Rails::Railtie
          initializer "action_dispatch-testing-integration-capybara.extensions" do
            ActiveSupport.on_load :action_dispatch_integration_test do
              include(Module.new do
                extend ActiveSupport::Concern

                included do
                  delegate :within, to: :page

                  setup do
                    integration_session.extend(Module.new do
                      def process(*arguments, **options, &block)
                        if @page && @page.driver.browser.respond_to?(:reset_cache!)
                          @page.driver.browser.reset_cache!
                        end

                        super
                      end

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
          end
        end
      end
    end
  end
end
