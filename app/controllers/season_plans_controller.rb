class SeasonPlansController < ApplicationController
  TEMPLATE = "virtuesgarden_season_v1".freeze

  AIMS_RANGE     = (5..8)
  EVIDENCE_RANGE = (1..3)
  MAX_AIM_NAME   = 160

  before_action :set_learner

  rate_limit to: 10, within: 1.minute, only: :create, by: -> { current_user.id }

  # shared/_ai_error's "Try again" button is a GET to the page it came from; a refresh lands here. Send both to the learner.
  def index
    redirect_to learner_path(@learner)
  end

  def show
    @season_plan = @learner.season_plans.find(params[:id])
  end

  def create
    raw = GeminiService.generate(template: TEMPLATE, variables: @learner.ai_variables)

    @season_plan = @learner.season_plans.create!(
      status:       "pending",
      gemini_raw:   raw,
      generated_at: Time.current
    )

    result = parse_season!(raw)
    @season_plan.update!(result.merge(status: "completed"))
    redirect_to learner_season_plan_path(@learner, @season_plan)

  rescue ParseError => e
    @season_plan.update!(status: "failed", failure_reason: e.message.truncate(250), gemini_raw: e.raw)
    redirect_to learner_season_plan_path(@learner, @season_plan)

  # Before GatekeeperError: CrisisError is a subclass. AiGatekeeper raised it on a crisis term, before any AI call.
  rescue GeminiService::CrisisError
    render :crisis, status: :unprocessable_entity

  rescue GeminiService::BudgetExceededError
    render "shared/ai_error_page", locals: { error_type: :budget_exceeded }, status: :unprocessable_entity

  rescue GeminiService::GatekeeperError
    render "shared/ai_error_page", locals: { error_type: :gatekeeper_blocked }, status: :unprocessable_entity

  rescue GeminiService::OutputGuardError
    render "shared/ai_error_page", locals: { error_type: :output_blocked }, status: :unprocessable_entity

  rescue GeminiService::TimeoutError
    render "shared/ai_error_page", locals: { error_type: :timeout }, status: :unprocessable_entity

  rescue GeminiService::GeminiError
    render "shared/ai_error_page", locals: { error_type: :error }, status: :unprocessable_entity
  end

  private

  def set_learner
    @learner = current_user.learners.find(params[:learner_id])
  end

  ParseError = Class.new(StandardError) do
    attr_reader :raw
    def initialize(msg, raw:)
      super(msg)
      @raw = raw
    end
  end

  # Validates the virtuesgarden_season_v1 JSON and returns the SeasonPlan attributes. Hard rules enforced here, not
  # trusted to the model:
  #   - 5-8 aims, each in one of the five areas AND in an area the guardian selected (gaps too);
  #   - a match is null or one of the offerings the guardian listed (stored in the guardian's spelling);
  #   - one gap per unmatched aim;
  #   - no output text tests, scores, grades, ranks, diagnoses or compares the child (NoScoreWords).
  def parse_season!(raw)
    fail_parse = ->(msg) { raise ParseError.new(msg, raw: raw) }

    stripped = raw.to_s.strip.gsub(/\A```(?:json)?\s*|\s*```\z/, "").strip
    parsed   = JSON.parse(stripped)
    fail_parse.("Expected a JSON object") unless parsed.is_a?(Hash)

    aims = parsed["aims"]
    fail_parse.("aims must be a list") unless aims.is_a?(Array)
    unless AIMS_RANGE.cover?(aims.size)
      fail_parse.("Expected #{AIMS_RANGE.min}-#{AIMS_RANGE.max} aims, got #{aims.size}")
    end
    aims = aims.each_with_index.map { |aim, i| parse_aim(aim, i + 1, fail_parse) }

    gaps = parsed.fetch("gaps", [])
    fail_parse.("gaps must be a list") unless gaps.is_a?(Array)
    gaps = gaps.each_with_index.map { |gap, i| parse_gap(gap, i + 1, fail_parse) }

    unmatched = aims.reject { |aim| aim["match"] }
    unless gaps.size == unmatched.size && gaps.map { |g| g["area"] }.sort == unmatched.map { |a| a["area"] }.sort
      fail_parse.("Expected one gap for each of the #{unmatched.size} aims with no match, got #{gaps.size}")
    end

    note = parsed["note_to_guardian"]
    fail_parse.("note_to_guardian is missing") unless note.is_a?(String) && note.strip.present?

    result = { aims: aims, gaps: gaps, note_to_guardian: note.strip }

    found = NoScoreWords.offending(result)
    if found.any?
      fail_parse.("The response used a word that scores or compares a child (\"#{found.first}\"), so it was not shown")
    end

    result
  rescue JSON::ParserError => e
    raise ParseError.new("JSON parse failed: #{e.message.truncate(120)}", raw: raw)
  end

  def parse_aim(aim, number, fail_parse)
    fail_parse.("Aim #{number} is not an object") unless aim.is_a?(Hash)

    area = parse_area(aim["area"], "Aim #{number}", fail_parse)
    name, why, first_step = %w[name why first_step].map do |key|
      value = aim[key]
      fail_parse.("Aim #{number} is missing #{key}") unless value.is_a?(String) && value.strip.present?
      value.strip
    end
    fail_parse.("Aim #{number}'s name is longer than #{MAX_AIM_NAME} characters") if name.length > MAX_AIM_NAME

    evidence = string_list(aim["evidence_ideas"])
    unless evidence && EVIDENCE_RANGE.cover?(evidence.size)
      fail_parse.("Aim #{number} needs #{EVIDENCE_RANGE.min}-#{EVIDENCE_RANGE.max} evidence_ideas")
    end

    { "area" => area, "name" => name, "why" => why, "first_step" => first_step,
      "match" => parse_match(aim["match"], number, fail_parse), "evidence_ideas" => evidence }
  end

  def parse_gap(gap, number, fail_parse)
    fail_parse.("Gap #{number} is not an object") unless gap.is_a?(Hash)

    area = parse_area(gap["area"], "Gap #{number}", fail_parse)
    name, close = %w[name what_would_close_it].map do |key|
      value = gap[key]
      fail_parse.("Gap #{number} is missing #{key}") unless value.is_a?(String) && value.strip.present?
      value.strip
    end
    { "area" => area, "name" => name, "what_would_close_it" => close }
  end

  def parse_area(area, label, fail_parse)
    unless Learner::AREAS.include?(area)
      fail_parse.("#{label} has area \"#{area.to_s.truncate(40)}\", which is not one of the five areas")
    end
    unless @learner.focus_areas.include?(area)
      fail_parse.("#{label} is in #{Learner.area_label(area)}, an area you did not select")
    end
    area
  end

  # null (or "none", production's spelling) means no match. Anything else must be an offering the guardian listed.
  def parse_match(match, number, fail_parse)
    return nil if match.nil? || (match.is_a?(String) && match.strip.downcase.in?([ "", "none" ]))
    fail_parse.("Aim #{number}'s match must be text or null") unless match.is_a?(String)

    @learner.offering_named(match) ||
      fail_parse.("Aim #{number} matched \"#{match.truncate(60)}\", which is not one of the offerings you listed")
  end

  # An array of non-blank strings, stripped; nil when the value is anything else.
  def string_list(value)
    return nil unless value.is_a?(Array) && value.all? { |v| v.is_a?(String) && v.strip.present? }
    value.map(&:strip)
  end
end
