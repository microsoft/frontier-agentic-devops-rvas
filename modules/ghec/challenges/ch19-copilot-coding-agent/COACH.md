# Ch19 — Copilot Cloud Agent — Coach Guide

> Audience: facilitators and graders. Pair with the student `README.md`.

## Grounding conversation (you will be called)

Students are **expected to call you** to talk through this challenge's real-world impact before they consider it done. This is a required completion step, not optional — it is how we keep the learning grounded in their actual day-to-day work.

**Their question:** Coach conversation — which class of GitHub issues in your repos is well-defined enough that the Copilot coding agent could handle it unsupervised, and what review gate would you trust before merging its PR? Talk it through with your coach and connect it to a real project, task, or workflow you own.

Use these follow-ups to steer the conversation:
- Name a specific label or issue template in your repos that tags well-scoped, low-risk tasks — what makes them safe to delegate?
- What is the review checklist or CI gate that would need to pass before you merged an agent-authored PR without deep inspection?
- What is the first issue you'd assign to the coding agent this week, and what outcome would make you confident enough to expand its scope?

## Facilitation notes
- **Goal in one line:** the student delegates a clear, bounded bug to the **Copilot cloud agent**, then **reviews and steers** it to a merged, correct fix — learning the human-in-the-loop boundary.
- **⚠️ Eligibility is the gate, not a footnote.** Before anything else, confirm the org has the **Copilot cloud agent policy enabled** and the repo is **non-EMU**. If the enterprise is **GHEMU**, the agent will not run — this challenge is **N/A** and the student should run it on a non-EMU org. `wth doctor ch19` warns, but verify by hand too.
- **Where students get stuck:**
  - **Nothing happens after assignment.** Either the policy is off, the user has no Copilot license, or the repo is EMU. Triage in that order.
  - **Expecting a non-draft PR.** The agent opens a **draft** PR and works incrementally — that's normal, not a failure.
  - **Over-scoped issue.** A vague or huge issue produces a sprawling, hard-to-review PR. Coach them to write tight, testable issues — the seeded one models this.
  - **Branch protection blocks the agent.** If they add a required ruleset, the agent's PR can stall; they must add **Copilot as a bypass actor** (or grant permission).
- **How to unblock without giving the answer:** ask "is the agent *allowed* to run here — policy on, license present, non-EMU?" and "how tightly does your issue define done?" (→ acceptance criteria drive agent quality).
- **Org-scoped note:** runs with an org + org-owner token; the **agent runs under Copilot's identity**, not the student's PAT. No enterprise owner required — but a **non-EMU** enterprise with the cloud-agent policy enabled **is** required.

## Grading rubric (point-weighted, 100 pts)
| Criterion | Points | What "full marks" looks like |
|---|---:|---|
| Eligibility confirmed | 10 | Policy enabled + non-EMU verified; understands EMU exclusion |
| Delegation triggers a session | 20 | Issue assigned to Copilot; **draft PR** opened referencing the issue |
| Reading the agent's work | 15 | Session log read; diff reviewed against acceptance criteria |
| Steering / iteration | 20 | At least one review comment; agent pushes **new commits** in response |
| Fix correctness + merge | 25 | Failing test green in PR CI; PR approved + merged to `main`; issue auto-closed |
| Reflection on the boundary | 10 | Clear write-up of where the agent fits vs where human review is essential |
| **Total** | **100** | |

## Automated verification hints
```bash
ORG=<org>; REPO=wth-ch19-copilot-coding-agent

# A PR authored by the Copilot agent exists (author is a Bot)
gh pr list --repo $ORG/$REPO --state all \
  --json number,title,isDraft,author,mergedAt \
  --jq '.[] | {number, isDraft, author: .author.login, mergedAt}'

# Confirm the merged PR closed the seeded issue
gh issue list --repo $ORG/$REPO --state closed --json number,title,stateReason

# CI on the latest PR run is green (the previously failing test now passes)
gh run list --repo $ORG/$REPO --limit 5 --json name,headBranch,conclusion

# Sanity: repo is small/seeded as expected
gh repo view $ORG/$REPO --json name,visibility,isInOrganization
```
- The clearest mastery signal is a **merged PR authored by the Copilot bot** that **closed the seeded issue** with **green CI**.
- For steering, have the student show the PR's **commit history** — multiple agent commits after a review comment proves iteration, not a one-shot.
- If the agent never produced a PR, it's almost always **eligibility** (policy off / no license / **EMU**) — not student error.

## Common pitfalls
- **EMU enterprise** — the agent silently never runs. This is the headline gotcha; confirm non-EMU first. Pure GHEMU customers: this challenge is **N/A** — skip it, don't debug it.
- **Cloud-agent policy disabled** (the Business/Enterprise default) — admin must enable it.
- **No Copilot license** on the assigning user — assignment does nothing.
- **Required ruleset added without a Copilot bypass actor** — the agent's PR stalls; add the bypass and document why.
- **Judging the draft PR as "broken"** — draft + incremental commits is the normal flow.
- **Token scope** — `repo` + `read:org` is enough for the student; the agent does not use the student's token.

## Teardown
```bash
wth teardown ch19 --org <org> --yes
./scripts/teardown.sh ch19 --org <org> --yes   # Bash
./scripts/teardown.ps1 ch19 --org <org> --yes  # PowerShell
```
- Removes only `wth-ch19-*` artifacts (prefix-guarded): the seeded repo (with its issue, PRs, runs).
- **Manual cleanup (if any):** none beyond the repo. The org **Copilot cloud agent policy** is an org setting, not a `wth-ch19-*` artifact — leave it as the org wants it. If you added Copilot as a ruleset bypass actor on a non-prefixed org ruleset, remove it by hand.

## Time budget
- Setup + eligibility check: ~30 min
- Part B (delegate + watch session): ~45 min
- Part C (review the draft PR): ~45 min
- Part D (steer + iterate): ~1 hr
- Part E (gate, approve, merge): ~45 min
- Part F (reflection): ~15 min
- **Total facilitated:** ~4 hrs across sessions (agent session caps ~59 min each).
