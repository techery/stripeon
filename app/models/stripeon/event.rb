module Stripeon
  class Event < ActiveRecord::Base
    self.inheritance_column = nil

    validates :id_on_stripe, :type, :ip_address, presence: true
    validates :id_on_stripe, uniqueness: true

    scope :unprocessed, -> { where processed: false }
    scope :of_type, ->(needle) { where type: needle }

    def mark_processed!
      update_attribute :processed, true
    end
  end
end
