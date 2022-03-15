class CreateAnoubisSsoClientGroups < ActiveRecord::Migration[7.0]
  def change
    create_table :groups do |t|
      t.string :ident, limit: 50
      t.json :title_locale

      t.timestamps
    end
    add_index :groups, [:ident], unique: true
  end
end
