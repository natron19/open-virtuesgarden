require "rails_helper"

RSpec.describe NoScoreWords do
  it "passes ordinary aims" do
    expect(described_class.clean?("Bake a loaf from start to finish, then share it with a neighbour.")).to be(true)
  end

  {
    "a score"           => "Her reading score is high.",
    "a grade level"     => "Reads at grade level for her age.",
    "a letter grade"    => "Earns a grade B in maths.",
    "a percentage"      => "Spells 80% of the words.",
    "the word percent"  => "Ninety percent of children can do this.",
    "a rank"            => "Ranked third among her cousins.",
    "a numbered level"  => "Swims at level 3.",
    "below average"     => "Slightly below average at writing.",
    "behind"            => "A little behind other children.",
    "ahead of"          => "Ahead of his class in maths.",
    "gifted"            => "A gifted young artist.",
    "delayed"           => "Speech seems delayed.",
    "deficit"           => "An attention deficit.",
    "a diagnosis"       => "Could be diagnosed with something.",
    "an assessment"     => "Start with an assessment.",
    "test results"      => "Look at the test results."
  }.each do |label, text|
    it "flags #{label}" do
      expect(described_class.clean?(text)).to be(false)
      expect(described_class.offending(text)).not_to be_empty
    end
  end

  it "checks every string in a JSON-shaped value" do
    value = { "aims" => [ { "name" => "Bake bread", "why" => "Ahead of the winter fair." } ], "note" => "Fine." }
    expect(described_class.offending(value)).to eq([ "Ahead of" ])
  end

  it "does not flag words that only contain a listed word" do
    expect(described_class.clean?("An upgrade to the bike, a frank talk, and a new scoreboard for the fair.")).to be(true)
  end
end
