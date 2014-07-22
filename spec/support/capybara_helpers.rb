module CapybaraHelpers
  module Matchers
    module Session

      def has_notice?(text)
        has_alert? text, selector: '.alert-success'
      end

      def has_error?(text)
        has_alert? text, selector: '.alert-error'
      end

      def has_alert?(text, selector: '.alert-error')
        find(selector).has_content? text
      end

      def has_validation_error?(input_id, text)
        error = find(:xpath, "//input[@id='#{input_id}']/following-sibling::small[@class='error']")

        error.has_content? text
      end

      def on_path?(expected_path)
        current_path == expected_path
      end
    end
  end
end

Capybara::Session.send(:include, CapybaraHelpers::Matchers::Session)
