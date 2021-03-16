class CreatePermissions < ActiveRecord::Migration[5.2]
  def change
    create_table :permissions do |t|
      t.integer :user_id
      t.string :name
      t.string :subject_class
      t.integer :subject_id
      t.string :action
      t.text :description
      t.integer :role_id
      t.timestamps
    end
  end
end
