# Code-side guard on AI output (not trusted to the model): nothing the AI writes about a child may test, score,
# grade, rank, diagnose or compare them.
#
# Ported unchanged from production VirtuesGarden's NoScoreWords (PRD §9), where a failed check discards the output.
# Here the season plan parser (SeasonPlansController#parse_season!) runs it on every string in the response and marks
# the plan failed with the offending word. It is a deliberately blunt list: "behind" also trips on "behind the
# counter". Blocking a harmless answer costs a Retry; letting a score through about a child costs more.
module NoScoreWords
  PATTERNS = [
    /\bscor(e|es|ed|ing)\b/i,
    /\bgrade\s*[0-9a-f]\b/i, /\ba grade\b/i, /\bgraded\b/i, /\bgrade level\b/i,
    /\bpercent(age)?\b/i, /%/,
    /\brank(s|ed|ing)?\b/i,
    /\blevel\s*[0-9]/i,
    /\b(below|above) average\b/i,
    /\bbehind\b/i, /\bahead of\b/i,
    /\bgifted\b/i, /\bdelayed\b/i, /\bdeficit\b/i,
    /\bdiagnos\w*/i, /\bassessment\b/i, /\btest results?\b/i
  ].freeze

  module_function

  # text: a String, or any JSON-shaped value (Hash/Array), checked as its joined strings.
  def clean?(text) = offending(text).empty?

  # The matched words, in pattern order (empty when clean).
  def offending(text)
    flat = flatten(text)
    PATTERNS.filter_map { |pattern| flat[pattern] }
  end

  def flatten(value)
    case value
    when Hash then value.values.map { |v| flatten(v) }.join(" ")
    when Array then value.map { |v| flatten(v) }.join(" ")
    else value.to_s
    end
  end
end
