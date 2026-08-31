# Ch19 — Copilot Cloud Agent

> Deliver a governed Copilot cloud-agent flow: assign an approved issue, review and steer its draft pull request, then merge through customer controls.

| | |
|---|---|
| Track | Automation & AI |
| Difficulty | Advanced *(per-track ramp)* |
| Duration | ~4 hrs total, multi-session |
| Minimum input | An org + an org-owner token. *(All activities are org-scoped — no enterprise owner required.)* |
| App | Provisioned starter repository (created by setup) |
| EMU compatible | no — the Copilot cloud agent is not available on EMU-owned repositories. Requires a non-EMU enterprise with the Copilot cloud agent policy enabled. N/A for pure GHEMU customers (see Prerequisites). |

## Delivery target

- Delivery target: an approved repository issue that the Copilot cloud agent attempts under review gates.
- Safety boundary: enable policy, grant bypasses, and assign issues only with approval from the accountable Copilot, security, and repository owners. Human review and merge approval stay with a person, never the agent.
- Evidence: the issue, draft pull request, session log, review decisions, and the approved-delegation record.
- Owner: the repository owner accepts merge control; the Copilot owner accepts policy and cost.

## Prerequisites
> ⚠️ Read this before starting — this activity has a hard prerequisite the others don't.
- An organization you own (or org-owner rights) on GitHub Enterprise Cloud.
- Copilot cloud agent must be enabled. Copilot Business/Enterprise has the cloud agent disabled by default — an admin must turn on the Copilot cloud agent policy for the org (and a Copilot license must cover the user assigning issues).
- NOT available on EMU repos. If your enterprise is Enterprise Managed Users (GHEMU), the cloud agent will not run on its repositories. This activity is N/A for pure GHEMU customers — run it on a non-EMU org. `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch19` warns about EMU.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch19 --org <org>` (least-privilege; for this activity: `repo` + `read:org`). The cloud agent itself runs under Copilot's identity, not your token.
- Local tooling: `gh >= 2.x`, `git`, `jq`.
- Note on limits: agent sessions are capped (~59 min) and run in an ephemeral Actions environment, consuming Actions minutes + Copilot premium requests.

## What you'll do
- Confirm the Copilot cloud agent is enabled and the repo is eligible (non-EMU).
- Assign an issue to Copilot and trigger an autonomous agent session.
- Read the agent's draft pull request and follow its session log as it works.
- Steer the agent with PR review comments and additional issue context, then iterate.
- Review and merge the agent's PR like any human contributor's — including required gates.
- Add Copilot as a ruleset bypass actor where branch protections would otherwise block its PR flow.

## Scenario
A GHEC customer wants engineers to delegate small, well-scoped bugs to the Copilot cloud agent and review the results. Validate that flow on a seeded repository with a known bug: write a precise issue, assign it to Copilot, inspect the draft PR and session log, then review and steer the change to a correct fix. The evidence should show which tasks suit the agent and where human review remains necessary.

> [!IMPORTANT]
> Default to an authorised customer repository issue that the Copilot cloud agent can safely attempt with review gates.
>
> Have a candidate? Use it everywhere this guide says `ghec-ch19-copilot-coding-agent`, and skip Setup below. Otherwise use the seeded sample below for validation only, then hand the validated operating model off to the customer owner.

## Sample test repository or environment
Skip if you brought your own repo/issue.

```bash
# Bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch19 --org <org>
```
```powershell
# PowerShell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch19 --org <org>
```

> `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch19 --org <org>` runs first and warns if the org looks EMU-managed or if the Copilot cloud agent policy can't be confirmed. Heed it — the agent won't run on EMU repos.

What setup creates (all artifacts namespaced `ghec-ch19-*`, idempotent, prefix-guarded teardown):
- A small seeded buggy repo `ghec-ch19-copilot-coding-agent` (NOT Juice Shop — kept small so agent runs stay short and gradable): a tiny app with a failing test that pins a single, clear bug.
- A CI workflow that runs the test suite (so the agent's fix can be verified green).
- A well-framed seeded issue describing the bug, repro, and acceptance criteria — ready to assign to Copilot.
- A printed Next steps block (including how to add Copilot as a bypass actor if you enable branch protection).

## Tasks
> Throughout, `ghec-ch19-copilot-coding-agent` is the fallback sample. If you brought your own artifact, substitute its name in every command and use your real history, teams, settings, or data as the material to work from.

### Part A — Confirm eligibility
1. Verify the policy. Confirm the org has the Copilot cloud agent enabled (Org Settings → Copilot → Policies) and that your user has a Copilot license.
2. Confirm non-EMU. Ensure the repo is not in an EMU-managed enterprise. If `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch19` flagged EMU, stop — this activity can't run here.
3. Open the seeded issue and read its repro + acceptance criteria so you can judge the agent's output later.

### Part B — Delegate to the agent
4. Assign the issue to Copilot. On the seeded issue, add Copilot as the assignee (Assignees → Copilot). This triggers an agent session.
5. Watch it start. Within a minute or two the agent opens a draft pull request referencing the issue. Open it.
6. Follow the session. Read the agent's progress/session log on the PR (its plan, the files it's touching, the commands it runs in the ephemeral environment).

### Part C — Review the draft PR
7. Read the diff critically. Does the change actually fix the pinned bug? Does it touch anything it shouldn't? Check CI on the PR.
8. Run/confirm the tests. Confirm the previously failing test is now green in the PR's CI run.
9. Leave a review. Comment on a specific line with a concrete request (e.g., "handle the empty-input case too" or "add a test for X").

### Part D — Steer and iterate
10. Request changes via the agent. Use a PR review comment or `@`-mention to ask Copilot to revise. Confirm it pushes new commits to the same PR in response.
11. Add missing context. If the first attempt missed an edge case, update the issue/PR with the detail and let the agent iterate. Note how prompt quality changes the result.

### Part E — Gate, approve & merge
12. (Optional) Add a branch protection / ruleset on `main` requiring the CI check + a review. If the agent's PR is now blocked from updating, add Copilot as a bypass actor (or grant the needed permission) and document why.
13. Mark ready & approve. When the change is correct, take the PR out of draft, give it your approving review, and merge it.
14. Confirm the fix landed. On `main`, confirm the test suite is green and the issue auto-closed via the PR link.

### Part F — Reflect (write-up)
15. Capture the operating boundary. In `docs/AGENT-NOTES.md`, record what the agent did well, where human review was essential, and which issue types are approved for delegation.

## Reference links
- About Copilot cloud agent — https://docs.github.com/en/copilot/concepts/agents/cloud-agent/about-cloud-agent
- Managing access to Copilot cloud agent — https://docs.github.com/en/copilot/concepts/agents/cloud-agent/access-management
- Using Copilot to work on an issue — https://docs.github.com/en/copilot/how-tos/use-copilot-agents/cloud-agent/start-copilot-sessions
- Customizing or restricting Copilot cloud agent — https://docs.github.com/en/copilot/how-tos/use-copilot-agents/cloud-agent
- Managing GitHub Copilot policies in your organization — https://docs.github.com/en/copilot/how-tos/administer-copilot/manage-for-organization/manage-policies
- `gh pr` CLI manual — https://cli.github.com/manual/gh_pr
