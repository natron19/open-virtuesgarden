FactoryBot.define do
  factory :learner do
    association :user
    first_name          { "Wren" }
    age                 { 9 }
    interests           { "Draws birds everywhere, takes apart old radios, and wants to bake bread on her own." }
    season_needs        { "More time outdoors, something Wren makes with her hands, and a friend her own age." }
    available_offerings { "Saturday bread class at St. Brigid's hall (ages 8-12)\nNature journaling walks at Linden Creek (ages 7-11)" }
    focus_areas         { Learner::AREAS }
  end
end
