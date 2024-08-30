class CreatePoints < ActiveRecord::Migration[7.1]
  def change
    create_table :points do |t|
      t.string :user, index: true
      t.integer :points
      t.references :question, null: false, foreign_key: true

      t.timestamps
    end
  end
end
