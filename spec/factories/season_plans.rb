FactoryBot.define do
  factory :season_plan do
    association :learner
    status       { "pending" }
    generated_at { nil }
    gemini_raw   { nil }

    trait :completed do
      status       { "completed" }
      generated_at { Time.current }
      gemini_raw   { "{}" }
      aims do
        [
          { "area" => "practical_skill", "name" => "Bake a loaf from start to finish",
            "why" => "This child keeps asking to bake bread alone.", "first_step" => "Bake one loaf together this weekend.",
            "match" => "Saturday bread class at St. Brigid's hall (ages 8-12)", "evidence_ideas" => [ "The finished loaf" ] },
          { "area" => "experience", "name" => "Open up an old radio with an adult",
            "why" => "Taking radios apart is how this child asks how things work.", "first_step" => "Find an old radio.",
            "match" => nil, "evidence_ideas" => [ "A labelled drawing of the inside" ] }
        ]
      end
      gaps do
        [ { "area" => "experience", "name" => "Open up an old radio with an adult",
            "what_would_close_it" => "An adult who repairs small electronics, with a second adult present." } ]
      end
      note_to_guardian { "This is a starting point to edit; whether she joins anything is your decision." }
    end

    trait :failed do
      status         { "failed" }
      generated_at   { Time.current }
      gemini_raw     { "malformed response" }
      failure_reason { "JSON parse failed: unexpected token" }
    end
  end
end
