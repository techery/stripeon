require 'state_machine'
require 'state_machine/audit_trail'
require 'ext/public_around_validation'
require 'stripe'
require 'draper'
require 'sidekiq'
require 'stripeon/engine'
require 'stripeon/pdf_receipt'
require 'stripeon/defaults'
require 'stripeon/configurator'

module Stripeon
  def self.config
    Configurator
  end
end
