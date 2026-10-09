class CreateLearners < ActiveRecord::Migration[8.1]
  def change
    create_table :learners, id: :uuid do |t|
      t.references :user, type: :uuid, null: false, foreign_key: true
      t.string  :first_name,           null: false
      t.integer :age,                  null: false
      t.text    :interests,            null: false
      t.text    :season_needs,         null: false
      t.text    :available_offerings
      t.string  :focus_areas,          null: false, default: [], array: true

      t.timestamps null: false
    end
  end
end
