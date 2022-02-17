class CreateMessages < ActiveRecord::Migration[7.0]
  def change
    create_table :messages do |t|
      t.string :channel
      t.string :user
      t.text :message
      t.text :raw

      t.timestamps
    end
  end
end
