class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|

      t.string :id_on_stripe
      t.string :email, null: false, default: ""

      t.timestamps
    end
  end
end
