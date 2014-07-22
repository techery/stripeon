require 'rails_helper'

module Stripeon
  RSpec.describe BaseMailer do
    describe "default values are correctly set" do
      it "has default from option" do
        expect(BaseMailer.default[:from]).to eql Defaults.email_from
      end
    end
  end
end
