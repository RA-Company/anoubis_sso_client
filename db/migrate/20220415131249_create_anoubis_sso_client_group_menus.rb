class CreateAnoubisSsoClientGroupMenus < ActiveRecord::Migration[7.0]
  def change
    create_table :group_menus do |t|
      t.references :group, index: true, foreign_key: true, default: 0
      t.references :menu, index: true, foreign_key: true, default: 0
      t.integer :access, default: 0

      t.timestamps
    end
    add_index :group_menus, [:group_id, :menu_id], unique: true
  end
end
