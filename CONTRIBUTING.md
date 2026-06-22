# Contributing

This project welcomes contributions and suggestions. Most contributions require you to
agree to a Contributor License Agreement (CLA) declaring that you have the right to,
and actually do, grant us the rights to use your contribution. For details, visit
https://cla.microsoft.com.

When you submit a pull request, a CLA-bot will automatically determine whether you need
to provide a CLA and decorate the PR appropriately (e.g., label, comment). Simply follow the
instructions provided by the bot. You will only need to do this once across all repositories using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/)
or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Content architecture contract

Challenge content lives under `modules/<moduleId>/challenges/<slug>/`. The build reads
`meta.yml` as the single source of truth and copies `README.md` and `COACH.md` into the
generated Pages data. Do not hand-edit generated files under `docs/assets/data/`; run
`npm run build` instead.

Outcome journeys live in [`outcomes.json`](outcomes.json). Use that file to curate existing
challenges into adoption, migration, security, agentic workflow, and cloud DevOps paths
without duplicating challenge content.

Every challenge directory must contain:

```text
meta.yml   # catalog metadata and dependency contract
README.md  # student guide
COACH.md   # facilitator guide, hints, expected outputs, common failures
```

### `meta.yml` required fields

| Field | Contract |
|---|---|
| `id` | Globally unique challenge id. Use `<module>-<local-id>` (`ghec-ch01`, `ghas-s02`, `ghaw-3-05`, `sre-agent-04`). Ids are stable and may have intentional gaps. |
| `title` | Short catalog title. |
| `module` | One of `ghec`, `ghas`, `ghaw`, `sre-agent`. |
| `track` | Track slug for the module; must match `docs/build.js` module config. |
| `difficulty` | `beginner`, `intermediate`, or `advanced`. |
| `duration_minutes` | Estimated student time in minutes. |
| `prerequisites` | Challenge ids that must be completed first. Empty means independent except for stated environment setup. |
| `prerequisite_capabilities` | Skills or access needed before starting; do not use this for challenge ids. |
| `description` | One-sentence catalog summary. |
| `success_criteria` | Observable outcomes that prove the challenge is complete. |
| `tags` | Search/filter terms. Use lowercase kebab-case where possible. |
| `app_dependency` | Runtime/sample dependency (`none`, `juice-shop`, `contoso-claims`, `contoso-app`, `seed`, or `seed-repo`). |
| `emu_compatible` | `true` when the challenge works in an EMU-controlled org; otherwise `false`. |
| `min_environment` | Lowest required scope: `org`, `repo`, or `codespace`. |
| `provision_creates` | Human-readable resources created by setup or student steps. Empty list is allowed. |
| `source_repo` | Source repository provenance. |
| `source_path` | Repository-relative source path. Do not use absolute paths or `..`. |
| `license` | Source license; currently `MIT`. |

Optional fields:

| Field | Contract |
|---|---|
| `tier` | `setup`, `core`, `stretch`, or `bonus`. Defaults to `core` in the build. |
| `references` | Source-backed docs and product links used by students or coaches. |
| `outcomes` | Outcome ids from `outcomes.json` when a challenge needs explicit membership beyond journey curation. |
| `personas` | Personas such as `platform-engineer`, `security-lead`, `developer`, `sre`, or `migration-lead`. |
| `business_value` | Value tags such as `reduce-migration-risk`, `shift-left-security`, or `automate-repetitive-work`. |
| `adoption_stage` | `assess`, `pilot`, `scale`, or `operate`. |

## Outcome journey contract

`outcomes.json` defines the business-facing paths shown on the home page and catalog filters.
Each outcome requires:

| Field | Contract |
|---|---|
| `id` | Stable kebab-case outcome id. |
| `name` | Business-facing journey name. |
| `tagline` | Short card summary. |
| `description` | Longer explanation of when to use the journey. |
| `personas` | Primary audience for the journey. |
| `adoption_stage` | Stages covered by the journey: `assess`, `pilot`, `scale`, `operate`. |
| `business_value` | Searchable value tags. |
| `source_platforms` | Relevant starting platforms, such as `azure-devops`, `bitbucket`, `gitlab`, `github`, or `greenfield`. |
| `challenge_ids` | Ordered list of existing challenge ids included in the journey. |
| `success_metrics` | Observable business outcomes coaches can use in workshop or account-team conversations. |

## Per-challenge QA rubric

Use this 100-point rubric for every new or materially changed challenge. Record manual
review results in PR comments or issue bodies, not in throwaway repo planning files.

| Area | Points | Pass standard |
|---|---:|---|
| Metadata and provenance | 15 | Required fields complete; ids stable; module/track valid; source attribution present; generated catalog matches source. |
| Independence and setup | 20 | Challenge can be started from a clean environment with only listed prerequisites/capabilities; no hidden state from previous challenges; app dependency acquisition is documented. |
| Student guide quality | 20 | README has clear goal, steps, validation commands/screens, expected outputs, cleanup notes where needed, and no dead/internal-only links. |
| Coach guide quality | 15 | COACH covers facilitator intent, hints, expected solution/evidence, timing, and common failure modes without leaking secrets. |
| Validation evidence | 15 | Build/audit pass; success criteria are objectively checkable; commands are current; external dependency versions or availability claims are source-backed. |
| Accessibility and operational safety | 10 | Works in intended org/account type; calls out Azure/billing/permissions risk; avoids destructive defaults and committed secrets. |
| Catalog fit and coverage | 5 | Challenge fills a real module/track need, avoids unnecessary duplication, and has useful tags for discovery. |

Score bands:

| Score | Decision |
|---:|---|
| 90-100 | Ship-ready. |
| 75-89 | Accept with tracked follow-ups; no P0/P1 issues. |
| 60-74 | Needs revision before merge unless explicitly approved as temporary scaffold. |
| 0-59 | Reject or rebuild. |

Severity levels:

| Severity | Definition | Merge policy |
|---|---|---|
| P0 | Build/audit failure, broken prerequisite graph, missing guide, unsafe instruction, secret exposure, or challenge cannot start. | Blocks merge. |
| P1 | Core learning path fails, hidden dependency, stale product instruction, dead required link, or misleading success criteria. | Blocks merge unless owner accepts documented risk. |
| P2 | Coach/student quality gap, weak evidence, missing optional metadata, incomplete cleanup, or confusing catalog fit. | May merge with assigned follow-up. |
| P3 | Editorial polish, tag improvement, minor timing mismatch, or optional reference update. | Non-blocking. |

### QA inventory format

For audit-friendly reviews, use one inventory object per challenge. JSON Lines works well
in PR comments, issue bodies, or generated local reports because it is machine-diffable
and does not require a repo planning markdown file.

```json
{"id":"ghas-s02","reviewed_at":"2026-06-19T09:05:03+02:00","reviewer":"name-or-role","score":92,"severity":"P3","decision":"ship","evidence":["npm run build","npm run audit","cold-start runbook followed"],"findings":[{"severity":"P3","area":"tags","summary":"Add oauth tag if the guide gains OAuth steps."}],"missing_candidate_decision":"none"}
```

Allowed `decision` values: `ship`, `ship-with-followups`, `revise`, `reject`,
`defer`, `candidate-accepted`, `candidate-declined`.

Required inventory keys: `id`, `reviewed_at`, `reviewer`, `score`, `severity`,
`decision`, `evidence`, `findings`, `missing_candidate_decision`.

## Catalog coverage and backlog decisions

Use these rules when deciding whether a missing challenge belongs in the backlog:

1. Preserve current scoped modules before adding new scope.
2. Prefer a gap-filling challenge over a duplicate topic.
3. Do not restore intentionally removed ids unless the original scope decision is reversed.
4. If a candidate needs a new product area, create a new module/track proposal rather than
   stretching an existing module.
5. Every accepted candidate needs an owner, source/provenance, dependency plan, and QA
   inventory entry before content work starts.
