# VirtuesGarden Demo - Build Tracker

**Spec:** [`virtuesgarden-demo-spec.md`](virtuesgarden-demo-spec.md)
**Process:** `OPEN-SOURCE-PLAYBOOK.md` steps 4-12
**Boilerplate:** open-base (scaffolded with `new-open-app.sh virtuesgarden "VirtuesGarden" "..."`)

| # | Phase | Status |
|---|---|---|
| 1 | Branding and config: `.env(.example)`, layout fallback name, leaf-green/marigold accent CSS, landing page, `DashboardController` removed | `[x]` |
| 2 | Models: `Learner`, `SeasonPlan` migrations, validations (first name only, age 4-18, five-area array), constants, associations | `[x]` |
| 3 | Routes and controllers: `LearnersController` CRUD, `SeasonPlansController` (nested, index redirect, rate limit, crisis and error rescues) | `[x]` |
| 4 | Views and Stimulus: dashboard, form, learner page, result page, parse-error and crisis pages, `generating`, `form_submit`, `download_markdown` | `[x]` |
| 5 | AI integration: `virtuesgarden_season_v1` prompt, `Learner#ai_variables` (age band, first name scrubbed), parser, `NoScoreWords` ported | `[x]` |
| 6 | Seeds: template, Wren example with a completed season, `demo_placeholder_v1` removed from seed, cases and DB | `[x]` |
| 7 | Guardrails and evals: `config/ai_guards.yml` (crisis terms for a child), `evals/cases/virtuesgarden_season_v1.yml` (8 cases + 1 crisis case) | `[x]` |
| 8 | Specs: models, `NoScoreWords`, crisis terms, requests; `bundle exec rspec` green; `bin/rails evals:guardrails` PASS | `[x]` |
| 9 | README rewrite, UI journey manifest (port 3132, crisis field), pre-publish check, local commit | `[x]` |

## Quick reference

```
learners_path                         GET  /learners   (also /dashboard)
new_learner_path                      GET  /learners/new
learner_path(l)                       GET  /learners/:id
edit_learner_path(l)                  GET  /learners/:id/edit
learner_season_plans_path(l)          POST /learners/:id/seasons   (GET redirects to the learner)
learner_season_plan_path(l, p)        GET  /learners/:id/seasons/:id
```

```
Template:   virtuesgarden_season_v1   (gemini-2.5-flash, 8192 max tokens, temperature 0.5)
Variables:  age_band, focus_areas, interests, season_needs, offerings   (never the first name)
JSON:       aims[5-8]{area, name, why, first_step, match|null, evidence_ideas[1-3]},
            gaps[]{area, name, what_would_close_it} (one per unmatched aim), note_to_guardian
Code rules: NoScoreWords, five-area enum, selected areas only, 5-8 aims, match in the listed offerings
Crisis:     config/ai_guards.yml crisis_terms → season_plans/crisis (988, Childhelp), no AI call
```

## Not done here (needs the owner)

- Live runs: `bin/rails evals:run` and `./ui-journey-fleet.sh --yes open-virtuesgarden` (real Gemini calls), and the
  free journeys `./ui-journey-fleet.sh --free open-virtuesgarden` (boots a server; not run by the build agent).
- `Open/README.md` app count and `git open repos.md` remote line (shared files, updated by the coordinator).
- GitHub repo creation and push.
