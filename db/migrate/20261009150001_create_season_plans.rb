class CreateSeasonPlans < ActiveRecord::Migration[8.1]
  def change
    create_table :season_plans, id: :uuid do |t|
      t.references :learner, type: :uuid, null: false, foreign_key: true
      t.string   :status, null: false, default: "pending"
      t.text     :gemini_raw
      t.string   :failure_reason
      t.datetime :generated_at

      t.jsonb :aims, null: false, default: []
      t.jsonb :gaps, null: false, default: []
      t.text  :note_to_guardian

      t.timestamps null: false
    end
    add_index :season_plans, :status
  end
end
