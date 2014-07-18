require 'rails_helper'

module Stripeon
  RSpec.describe SubscriptionMailer do
    [:create_subscription_mail, :expire_subscription_mail].each do |mail_function|
      describe ".#{mail_function}(customer_id, subscription_id)" do
        let!(:subscription) { create :stripeon_subscription }
        let!(:customer) { subscription.customer }

        before { expect(User).to receive(:find).with(1).and_return(customer) }

        subject(:mail) { SubscriptionMailer.send mail_function, 1, subscription.id }

        it "delivers email with correct subject" do
          expect(mail.subject).to eql I18n.t("stripeon.subscription_mailer.#{mail_function}.subject")
        end

        it "delivers email to customer's email" do
          expect(mail.to).to match_array [customer.email]
        end

        it "delivers multipart email" do
          expect(mail.html_part).not_to be_nil
          expect(mail.text_part).not_to be_nil
        end
      end
    end

    describe ".upgrade_subscription_mail(customer_id, subscription_id, 42)" do
      let!(:subscription) { create :stripeon_subscription }
      let!(:customer) { subscription.customer }

      subject(:mail) { SubscriptionMailer.upgrade_subscription_mail customer.id, subscription.id, 42 }

      it "delivers email with correct subject" do
        expect(mail.subject).to eql I18n.t("stripeon.subscription_mailer.upgrade_subscription_mail.subject")
      end

      it "delivers email to customer's email" do
        expect(mail.to).to match_array [customer.email]
      end

      it "delivers multipart email" do
        expect(mail.html_part).not_to be_nil
        expect(mail.text_part).not_to be_nil
      end
    end
  end
end
