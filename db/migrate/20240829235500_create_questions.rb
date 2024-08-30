class CreateQuestions < ActiveRecord::Migration[7.1]
  def change
    create_table :questions do |t|
      t.string :prompt
      t.string :answer
      t.datetime :last_asked_at

      t.timestamps
    end
  end
end
