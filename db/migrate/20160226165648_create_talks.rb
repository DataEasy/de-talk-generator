class CreateTalks < ActiveRecord::Migration
  def change
    create_table :talks do |t|
      t.string :first_name
      t.string :last_name
      t.integer :number
      t.string :title
      t.string :subtitle
      t.date :date
      t.time :time
      t.string :target
      t.string :filename
      t.references :user
      t.boolean :published

      t.timestamps null: false
    end

    add_foreign_key :talks, :users
  end
end
