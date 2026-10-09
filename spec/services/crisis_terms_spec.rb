require "rails_helper"

# The crisis terms in config/ai_guards.yml, as AiGatekeeper applies them to what a guardian writes about a child.
RSpec.describe "Crisis terms (config/ai_guards.yml)" do
  [
    "He keeps hurting himself and I found marks on his arms.",
    "She told me she wants to die.",
    "I think she is hurting herself at night.",
    "He said he wanted to die after school.",
    "I am worried he might kill himself.",
    "She is being abused by someone at home.",
    "He is not safe at home.",
    "Honestly I want to end my life and I don't know who to talk to."
  ].each do |text|
    it "routes \"#{text}\" to crisis resources" do
      expect { AiGatekeeper.check!(text) }.to raise_error(GeminiService::CrisisError)
    end
  end

  [
    "Says he is dying to learn archery and loves killer sudoku.",
    "He hurt his wrist falling off his bike, so climbing is out.",
    "She cried when the spider dies at the end of her favourite book.",
    "Wants to try every role in the school play, even the villain who gets killed in act two."
  ].each do |text|
    it "lets the look-alike \"#{text}\" through" do
      expect(AiGatekeeper.check!(text)).to be(true)
    end
  end
end
