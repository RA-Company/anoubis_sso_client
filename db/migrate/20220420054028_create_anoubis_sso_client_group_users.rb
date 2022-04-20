class CreateAnoubisSsoClientGroupUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :group_users do |t|
      t.references :group, index: true, foreign_key: true, default: 0
      t.references :user, index: true, foreign_key: true, default: 0

      t.timestamps
    end
  end
end
