module Stripeon
  class BaseMailer < ActionMailer::Base
    default from: Defaults.email_from

    layout 'stripeon/mail'
  end
end
