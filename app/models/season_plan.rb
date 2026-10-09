class SeasonPlan < ApplicationRecord
  belongs_to :learner
  has_one :user, through: :learner

  STATUSES = %w[pending completed failed].freeze

  validates :status, inclusion: { in: STATUSES }

  def completed? = status == "completed"
  def failed?    = status == "failed"

  # The learner was edited after this season was proposed.
  def stale?
    generated_at.present? && learner.updated_at > generated_at
  end

  def matched_aims   = aims.select { |aim| aim["match"].present? }
  def unmatched_aims = aims.reject { |aim| aim["match"].present? }

  # Aims grouped by area, in the five-area order, skipping empty areas.
  def aims_by_area
    Learner::AREAS.filter_map do |area|
      in_area = aims.select { |aim| aim["area"] == area }
      [ area, in_area ] if in_area.any?
    end
  end

  def summary
    "#{aims.size} aims, #{matched_aims.size} matched, #{gaps.size} #{gaps.size == 1 ? 'gap' : 'gaps'}"
  end

  def to_markdown
    lines = []
    lines << "# A season of aims for #{learner.first_name}, age #{learner.age}"
    lines << ""
    lines << "_Proposed #{generated_at&.strftime('%Y-%m-%d') || 'at an unknown date'} by #{ENV.fetch('APP_NAME', 'VirtuesGarden Demo')}. " \
             "AI-generated: a starting point for you to edit, not an assessment. It never tests, scores, ranks or " \
             "diagnoses a child, and it places no child anywhere. You decide what to keep._"
    lines << ""
    lines << "**Areas:** #{learner.focus_area_labels.join(', ')}"
    lines << ""
    aims_by_area.each do |area, area_aims|
      lines << "## #{Learner.area_label(area)}"
      lines << ""
      area_aims.each do |aim|
        lines << "### #{aim['name']}"
        lines << ""
        lines << aim["why"].to_s
        lines << ""
        lines << "- **First step:** #{aim['first_step']}"
        lines << "- **Match:** #{aim['match'].presence || 'nothing listed yet (a gap)'}"
        lines << "- **Evidence to keep:** #{Array(aim['evidence_ideas']).join('; ')}"
        lines << ""
      end
    end
    if gaps.any?
      lines << "## Gaps: what nobody offers yet"
      lines << ""
      gaps.each do |gap|
        lines << "- **#{gap['name']}** (#{Learner.area_label(gap['area'])}): #{gap['what_would_close_it']}"
      end
      lines << ""
    end
    lines << "## A note for you"
    lines << ""
    lines << note_to_guardian.to_s
    lines << ""
    lines.join("\n")
  end

  def markdown_filename
    slug = learner.first_name.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-|-\z/, "").presence || "learner"
    "#{slug}-season-of-aims.md"
  end
end
