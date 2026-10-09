require "rails_helper"

RSpec.describe Learner, type: :model do
  describe "validations" do
    it "is valid with the factory attributes" do
      expect(build(:learner)).to be_valid
    end

    it "requires a user" do
      expect(build(:learner, user: nil)).not_to be_valid
    end

    it "takes a first name only: no surname, no digits, at most 30 characters" do
      expect(build(:learner, first_name: "")).not_to be_valid
      expect(build(:learner, first_name: "Wren Abernathy")).not_to be_valid
      expect(build(:learner, first_name: "Wren2")).not_to be_valid
      expect(build(:learner, first_name: "x" * 31)).not_to be_valid
      expect(build(:learner, first_name: "Mary-Kate")).to be_valid
      expect(build(:learner, first_name: "D'Arcy")).to be_valid
      expect(build(:learner, first_name: "Zoë")).to be_valid
    end

    it "strips the first name" do
      expect(create(:learner, first_name: "  Wren ").first_name).to eq("Wren")
    end

    it "requires a whole-number age from 4 to 18" do
      expect(build(:learner, age: nil)).not_to be_valid
      expect(build(:learner, age: 3)).not_to be_valid
      expect(build(:learner, age: 19)).not_to be_valid
      expect(build(:learner, age: 9.5)).not_to be_valid
      expect(build(:learner, age: 4)).to be_valid
      expect(build(:learner, age: 18)).to be_valid
    end

    it "requires interests and season needs of 10 to 1500 characters" do
      expect(build(:learner, interests: "Mud")).not_to be_valid
      expect(build(:learner, interests: "x" * 1501)).not_to be_valid
      expect(build(:learner, season_needs: "")).not_to be_valid
      expect(build(:learner, season_needs: "x" * 1501)).not_to be_valid
    end

    it "allows no offerings but caps them at 12 lines of at most 120 characters" do
      expect(build(:learner, available_offerings: nil)).to be_valid
      expect(build(:learner, available_offerings: (1..13).map { |i| "Club #{i}" }.join("\n"))).not_to be_valid
      expect(build(:learner, available_offerings: "x" * 121)).not_to be_valid
    end

    it "requires at least one focus area and keeps only the five, in order" do
      expect(build(:learner, focus_areas: [])).not_to be_valid
      expect(build(:learner, focus_areas: [ "", "sports" ])).not_to be_valid
      learner = build(:learner, focus_areas: [ "", "service", "sports", "academics" ])
      expect(learner).to be_valid
      expect(learner.focus_areas).to eq(%w[academics service])
    end
  end

  describe "constants" do
    it "lists the five areas, each with a label" do
      expect(Learner::AREAS).to eq(%w[academics character practical_skill service experience])
      expect(Learner::AREA_LABELS.keys).to eq(Learner::AREAS)
      expect(Learner.area_label("practical_skill")).to eq("Practical skill")
    end
  end

  describe "associations" do
    it "destroys its season plans" do
      plan = create(:season_plan, :completed)
      expect { plan.learner.destroy }.to change(SeasonPlan, :count).by(-1)
    end

    it "has the newest plan as latest_season_plan" do
      learner = create(:learner)
      create(:season_plan, :completed, learner: learner, generated_at: 2.days.ago)
      newest = create(:season_plan, :completed, learner: learner, generated_at: 1.hour.ago)
      expect(learner.reload.latest_season_plan).to eq(newest)
    end
  end

  describe "#offerings" do
    it "splits lines, drops bullets, blanks and repeats" do
      learner = build(:learner, available_offerings: "- Chess club\n\n* Choir\nchess club\n  Bread class  ")
      expect(learner.offerings).to eq([ "Chess club", "Choir", "Bread class" ])
    end
  end

  describe "#ai_variables" do
    let(:learner) do
      build(:learner, first_name: "Wren", age: 9,
                      interests: "Wren draws birds. WREN loves radios. Wrenna is her cousin.",
                      season_needs: "A friend for Wren.",
                      available_offerings: "Bread class (ages 8-12)",
                      focus_areas: %w[academics service])
    end

    it "sends an age band, the areas, and the offerings, never the first name" do
      vars = learner.ai_variables
      expect(vars.keys).to eq(%i[age_band interests season_needs offerings focus_areas])
      expect(vars[:age_band]).to eq("8 to 9")
      expect(vars[:focus_areas]).to eq("academics, service")
      expect(vars[:offerings]).to eq("- Bread class (ages 8-12)")
      expect(vars.values.join(" ")).not_to match(/\bWren\b/i)
    end

    it "replaces the first name with \"this child\", word-bounded and case-insensitive" do
      expect(learner.ai_variables[:interests]).to eq("this child draws birds. this child loves radios. Wrenna is her cousin.")
      expect(learner.ai_variables[:season_needs]).to eq("A friend for this child.")
    end

    it "says None listed when there are no offerings" do
      learner.available_offerings = ""
      expect(learner.ai_variables[:offerings]).to eq("None listed")
    end
  end

  describe "#offering_named" do
    it "returns the listed offering in the guardian's spelling, ignoring case and spacing" do
      learner = build(:learner, available_offerings: "Bread class at St. Brigid's (ages 8-12)")
      expect(learner.offering_named("bread class at  st. brigid's (ages 8-12)")).to eq("Bread class at St. Brigid's (ages 8-12)")
      expect(learner.offering_named("Pottery class")).to be_nil
    end

    it "matches the scrubbed text the AI saw when an offering contains the first name" do
      learner = build(:learner, first_name: "Wren", available_offerings: "Wren's aunt's pottery afternoons")
      expect(learner.offering_named("this child's aunt's pottery afternoons")).to eq("Wren's aunt's pottery afternoons")
    end
  end
end
