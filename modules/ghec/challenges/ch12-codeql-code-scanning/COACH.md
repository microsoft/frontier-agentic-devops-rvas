# Ch12 — Code Scanning with CodeQL & Autofix — Coach Guide

> Audience: facilitators and graders. Pair with the student `README.md`.

## Grounding conversation (you will be called)

**Required coach check-in:** before completion, ask the learner to connect the exercise to work they actually own.

**Their question:** Coach conversation — pick a codebase you own or contribute to: what class of vulnerability (injection, path traversal, auth bypass) do you most fear is hiding there right now, and how would a CodeQL custom query surface it before your next release? Talk it through with your coach and connect it to a real project, task, or workflow you own.

> **Bring-your-own grading:** prefer students who ran this on a **real artifact they own** over the `ghec-ch12-juice-shop` sample. If they used the sample, confirm they can name the actual repo, team, project, or workflow they'll apply this to and any blockers. The lasting outcome is the goal; the sample is fallback.

Use these follow-ups to steer the conversation:
- Name the specific codebase — what language, how old, and what's your current static analysis story for it?
- What is the data-flow or taint path you'd want CodeQL to trace in that repo?
- What is one QL query or built-in suite you could add to that repo's Actions workflow before next week?

## Facilitation notes
- **Goal in one line:** the student stands up CodeQL (default *and* advanced), reads real vulnerability findings via their data-flow paths, applies Autofix with judgment, and makes scanning a merge gate.
- **Where students get stuck:**
  - **Default vs advanced confusion.** Default setup is one-click but opaque; advanced is a workflow they own. Make sure they *replace* default with advanced (you can't run both default and advanced for the same language).
  - **Wrong language pack.** Juice Shop is TS/JS — the pack is **`javascript-typescript`** (one combined pack), not separate `javascript` + `typescript`. The Web3/Solidity bits are out of scope.
  - **Required-check name.** The required context is the **CodeQL results** check, not the Actions job name. Show them the real check name on a PR.
  - **Autofix over-trust.** Students click "commit suggestion" without reading it. The learning objective is *reviewing* the patch and knowing when Autofix is wrong.
  - **Scan latency.** `security-extended` runs longer than the default suite. Set expectations — the first advanced run can take several minutes.
- **How to unblock without giving the answer:** ask "what's the path from user input to the dangerous sink?" (→ data-flow), and "what *exact* check does the merge gate wait for?" (→ the code-scanning results context).
- **Org-scoped note:** runs with just an org + org-owner token. Public repo = free CodeQL. `security_events` scope is needed for the alerts/analyses API; `workflow` to push the advanced workflow.

## Grading rubric (point-weighted, 100 pts)
| Criterion | Points | What "full marks" looks like |
|---|---:|---|
| Default setup + first scan (Part A) | 15 | Default setup ran; at least one analysis recorded |
| Advanced workflow (Part B) | 25 | `codeql.yml` scans `javascript-typescript` with `security-extended`; run is green and produces alerts |
| Alert triage (Part C) | 25 | ≥3 alerts triaged; one dismissed with a reason via API; data-flow understood |
| Copilot Autofix (Part D) | 15 | Autofix applied to ≥1 alert; student can explain the patch |
| Required-check gating (Part E) | 20 | Code-scanning check required on main; seeded vulnerable PR blocked until resolved |
| **Total** | **100** | |

## Automated verification hints
Use these to check Definition of Done quickly (prefer `gh` CLI / API over manual clicks):
```bash
ORG=<org>; REPO=ghec-ch12-juice-shop   # swap REPO for the student's own repo if they brought one

# Repo exists and is public
gh repo view $ORG/$REPO --json name,visibility

# Advanced workflow present and pinned to the right pack + suite
gh api repos/$ORG/$REPO/contents/.github/workflows/codeql.yml -H "Accept: application/vnd.github.raw" \
  | grep -E "javascript-typescript|security-extended|languages:|queries:"

# CodeQL analyses exist (tool name = CodeQL)
gh api repos/$ORG/$REPO/code-scanning/analyses --jq '.[0] | {tool: .tool.name, ref, created_at}'

# Open alerts with rule + severity (expect injection/XSS findings)
gh api repos/$ORG/$REPO/code-scanning/alerts --paginate \
  --jq '.[] | select(.state=="open") | {number, rule: .rule.id, severity: .rule.security_severity_level}'

# Dismissed alerts (triage evidence)
gh api repos/$ORG/$REPO/code-scanning/alerts --paginate \
  --jq '.[] | select(.state=="dismissed") | {number, reason: .dismissed_reason}'

# Required status checks on main (expect the CodeQL results context)
gh api repos/$ORG/$REPO/branches/main/protection/required_status_checks --jq '.contexts'
```
- **Pack check:** the workflow grep must show `javascript-typescript`. Separate `javascript`/`typescript` entries → partial credit; wrong language → no marks for Part B.
- **Gating check:** the `required_status_checks/.contexts` list must include the code-scanning context, and the student should demonstrate the vulnerable PR's merge button disabled.
- **Autofix:** look for a commit on a branch authored via Autofix or a resolved alert that traces to a student-reviewed suggestion.

## Common pitfalls
- **Running default + advanced together** for the same language → conflicting analyses. Disable default before advanced.
- **`security_events` scope missing** → alerts/analyses API 403. Fix: `gh auth refresh -s security_events`.
- **Required check never satisfied** because they required the Actions job name instead of the code-scanning results context.
- **Expecting instant alerts** — `security-extended` is slower; wait for the run to finish.
- **Private repo without a license** → CodeQL won't run. Keep the repo public.

## Useful references for coaching

- [About code scanning](https://docs.github.com/en/code-security/code-scanning/introduction-to-code-scanning/about-code-scanning), [Configuring default setup for code scanning](https://docs.github.com/en/code-security/code-scanning/enabling-code-scanning/configuring-default-setup-for-code-scanning).

## Teardown
```bash
bash modules/ghec/resources/provisioning/scripts/setup.sh teardown ch12 --org <org> --yes   # Bash
modules/ghec/resources/provisioning/scripts/setup.ps1 teardown ch12 --org <org> --yes  # PowerShell
```
- Removes only `ghec-ch12-*` artifacts (prefix-guarded): the imported `ghec-ch12-juice-shop` repo (which carries its workflows, analyses, and alerts).
- **Manual cleanup (if any):** none. Deleting the repo removes its CodeQL configuration, runs, and alerts.

## Time budget
- Setup + read: ~30 min
- Part A (default setup): ~30 min
- Part B (advanced workflow): ~1 hr
- Part C (triage): ~1.25 hrs
- Part D (Autofix): ~45 min
- Part E (required-check gating): ~1 hr
- **Total facilitated:** ~5 hrs across sessions.
