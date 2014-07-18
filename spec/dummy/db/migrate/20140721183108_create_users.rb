class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|

      t.string :id_on_stripe

      t.timestamps
    end
  end
end
