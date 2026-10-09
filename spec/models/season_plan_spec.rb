require "rails_helper"

RSpec.describe SeasonPlan, type: :model do
  describe "validations" do
    it "is valid with the factory attributes" do
      expect(build(:season_plan)).to be_valid
    end

    it "requires a learner" do
      expect(build(:season_plan, learner: nil)).not_to be_valid
    end

    it "accepts every known status and rejects others" do
      SeasonPlan::STATUSES.each { |s| expect(build(:season_plan, status: s)).to be_valid }
      expect(build(:season_plan, status: "unknown")).not_to be_valid
    end

    it "lists the statuses" do
      expect(SeasonPlan::STATUSES).to eq(%w[pending completed failed])
    end
  end

  describe "associations" do
    it "has a user through its learner" do
      plan = create(:season_plan)
      expect(plan.user).to eq(plan.learner.user)
    end
  end

  describe "defaults" do
    it "starts pending with empty lists" do
      plan = SeasonPlan.create!(learner: create(:learner))
      expect(plan.status).to eq("pending")
      expect([ plan.aims, plan.gaps ]).to all(eq([]))
    end
  end

  describe "helpers" do
    let(:plan) { create(:season_plan, :completed) }

    it "splits matched and unmatched aims and summarises" do
      expect(plan.matched_aims.size).to eq(1)
      expect(plan.unmatched_aims.size).to eq(1)
      expect(plan.summary).to eq("2 aims, 1 matched, 1 gap")
    end

    it "groups aims by area in the five-area order" do
      expect(plan.aims_by_area.map(&:first)).to eq(%w[practical_skill experience])
    end
  end

  describe "#stale?" do
    it "is true when the learner changed after the plan" do
      plan = create(:season_plan, :completed, generated_at: 1.hour.ago)
      plan.learner.update!(season_needs: "Something new for this season.")
      expect(plan.stale?).to be(true)
    end

    it "is false when the plan is newer than the learner" do
      plan = create(:season_plan, :completed, generated_at: 1.minute.from_now)
      expect(plan.stale?).to be(false)
    end
  end

  describe "#to_markdown" do
    let(:plan) { create(:season_plan, :completed) }

    it "includes the learner, the disclaimer, each area, the aims, the gaps and the note" do
      md = plan.to_markdown
      expect(md).to include("# A season of aims for Wren, age 9")
      expect(md).to include("not an assessment")
      expect(md).to include("## Practical skill", "### Bake a loaf from start to finish", "**First step:** Bake one loaf together this weekend.")
      expect(md).to include("**Match:** Saturday bread class at St. Brigid's hall (ages 8-12)")
      expect(md).to include("**Match:** nothing listed yet (a gap)")
      expect(md).to include("## Gaps: what nobody offers yet", "An adult who repairs small electronics")
      expect(md).to include("## A note for you", plan.note_to_guardian)
    end

    it "names the file after the first name" do
      expect(plan.markdown_filename).to eq("wren-season-of-aims.md")
    end
  end
end
