# One child, recorded by their guardian with a first name and an age only (no surname, school, birthday or photo).
# The child never signs in. The AI never receives the first name: see #ai_variables.
class Learner < ApplicationRecord
  belongs_to :user
  has_many :season_plans, dependent: :destroy
  has_one :latest_season_plan,
          -> { order(generated_at: :desc, created_at: :desc) },
          class_name: "SeasonPlan"

  # The five areas, in display order. Production VirtuesGarden's GARDEN_AREA_ENUM.
  AREAS = %w[academics character practical_skill service experience].freeze

  AREA_LABELS = {
    "academics"       => "Academics",
    "character"       => "Character",
    "practical_skill" => "Practical skill",
    "service"         => "Service",
    "experience"      => "Experience"
  }.freeze

  AGES          = (4..18)
  MAX_OFFERINGS = 12
  THIS_CHILD    = "this child".freeze

  # A first name only: letters, with an optional hyphen or apostrophe ("Mary-Kate", "D'Arcy"). No spaces, so no surname.
  FIRST_NAME_FORMAT = /\A\p{L}[\p{L}'’-]*\z/

  normalizes :first_name, with: ->(name) { name.strip }
  normalizes :focus_areas, with: ->(areas) { AREAS & Array(areas).map(&:to_s) }

  validates :first_name, presence: true, length: { maximum: 30 },
                         format: { with: FIRST_NAME_FORMAT, message: "should be a first name only, with no surname" }
  validates :age, presence: true, numericality: { only_integer: true, in: AGES }
  validates :interests,    presence: true, length: { in: 10..1500 }
  validates :season_needs, presence: true, length: { in: 10..1500 }
  validates :available_offerings, length: { maximum: 1500 }
  validates :focus_areas, presence: { message: "needs at least one area" }
  validate  :offerings_within_limits

  def self.area_label(area) = AREA_LABELS.fetch(area.to_s, area.to_s.humanize)

  def focus_area_labels = focus_areas.map { |a| self.class.area_label(a) }

  # The guardian's offerings, one per line, blank lines and repeats dropped.
  def offerings
    available_offerings.to_s.lines.map { |l| l.strip.sub(/\A[-*•]\s*/, "") }.reject(&:blank?).uniq { |o| o.downcase }
  end

  # Variables for virtuesgarden_season_v1. The first name never leaves the app: the AI gets an age band (as production
  # does) and the guardian's text with every occurrence of the first name replaced by "this child".
  def ai_variables
    {
      age_band:     age_band,
      interests:    scrub(interests),
      season_needs: scrub(season_needs),
      offerings:    ai_offerings.any? ? ai_offerings.map { |o| "- #{o}" }.join("\n") : "None listed",
      focus_areas:  focus_areas.join(", ")
    }
  end

  # The offerings exactly as the AI sees them (scrubbed), index-aligned with #offerings.
  def ai_offerings = offerings.map { |o| scrub(o) }

  # The listed offering an AI "match" names, in the guardian's own spelling; nil when it names none of them.
  def offering_named(match)
    key = normalize_offering(match)
    index = ai_offerings.index { |o| normalize_offering(o) == key }
    index && offerings[index]
  end

  def age_band = "#{age - 1} to #{age}"

  # Replace the first name, word-bounded and case-insensitive, wherever the guardian typed it.
  def scrub(text)
    return text.to_s if first_name.blank?
    text.to_s.gsub(/(?<![\p{L}])#{Regexp.escape(first_name)}(?![\p{L}])/i, THIS_CHILD)
  end

  private

  def normalize_offering(text) = text.to_s.downcase.gsub(/\s+/, " ").strip

  def offerings_within_limits
    list = offerings
    errors.add(:available_offerings, "can list at most #{MAX_OFFERINGS} offerings") if list.size > MAX_OFFERINGS
    errors.add(:available_offerings, "should keep each offering to one line of at most 120 characters") if list.any? { |o| o.length > 120 }
  end
end
