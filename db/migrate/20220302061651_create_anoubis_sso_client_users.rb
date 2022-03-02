class CreateAnoubisSsoClientUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :uuid, limit: 40, null: false
      t.string :sso_uuid, limit: 40, null: false
      t.string :email, limit: 100, null: false
      t.string :name, limit: 100, null: false
      t.string :surname, limit: 100, null: false

      t.timestamps
    end
    add_index :users, [:uuid], unique: true
    add_index :users, [:sso_uuid], unique: true
  end
end
