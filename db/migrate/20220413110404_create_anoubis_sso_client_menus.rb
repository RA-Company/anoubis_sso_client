class CreateAnoubisSsoClientMenus < ActiveRecord::Migration[7.0]
  def change
    create_table :menus do |t|
      t.string :mode, limit: 200
      t.string :action, limit: 50
      t.references :menu, index: true, foreign_key: true
      t.integer :tab, null: false, default: 0
      t.integer :position, null: false, default: 0
      t.integer :page_size, null: false, default: 20
      t.integer :state, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.json :title_locale
      t.json :page_title_locale
      t.json :short_title_locale

      t.timestamps
    end
    add_index :menus, [:mode], unique: true
    add_index :menus, :tab
  end
end
