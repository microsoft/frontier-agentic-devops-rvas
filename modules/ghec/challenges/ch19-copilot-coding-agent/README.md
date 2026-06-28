# Ch19 — Copilot Cloud Agent

> By the end of this challenge you can delegate a real bug to the GitHub Copilot cloud agent — assign it an issue, watch it open a draft pull request, and review, steer, and merge its work — on a small seeded repo using an org and an org-owner token.

| | |
|---|---|
| **Track** | Automation & AI |
| **Difficulty** | Advanced *(per-track ramp)* |
| **Duration** | ~4 hrs total, multi-session |
| **Minimum input** | An **org** + an **org-owner token**. *(All challenges are org-scoped — no enterprise owner required.)* |
| **App** | seed |
| **EMU compatible** | **no** — the Copilot cloud agent is **not available on EMU-owned repositories**. Requires a **non-EMU enterprise** with the **Copilot cloud agent policy enabled**. **N/A for pure GHEMU customers** (see Prerequisites). |

## Prerequisites
> ⚠️ **Read this before starting — this challenge has a hard prerequisite the others don't.**
- An organization you own (or org-owner rights) on GitHub Enterprise Cloud.
- **Copilot cloud agent must be enabled.** Copilot Business/Enterprise has the cloud agent **disabled by default** — an admin must turn on the **Copilot cloud agent** policy for the org (and a Copilot license must cover the user assigning issues).
- **NOT available on EMU repos.** If your enterprise is **Enterprise Managed Users (GHEMU)**, the cloud agent will not run on its repositories. This challenge is **N/A for pure GHEMU customers** — run it on a non-EMU org. `wth doctor ch19` warns about EMU.
- A token with the scopes listed by `wth doctor ch19 --org <org>` (least-privilege; for this challenge: `repo` + `read:org`). The cloud agent itself runs under Copilot's identity, not your token.
- Local tooling: `gh >= 2.x`, `git`, `jq`.
- **Note on limits:** agent sessions are capped (~59 min) and run in an ephemeral Actions environment, consuming Actions minutes + Copilot premium requests.

## Learning objectives
By completing this challenge you will:
- Confirm the **Copilot cloud agent** is enabled and the repo is **eligible** (non-EMU).
- **Assign an issue to Copilot** and trigger an autonomous agent session.
- Read the agent's **draft pull request** and follow its **session log** as it works.
- **Steer the agent** with PR review comments and additional issue context, then iterate.
- **Review and merge** the agent's PR like any human contributor's — including required gates.
- Add **Copilot as a ruleset bypass actor** where branch protections would otherwise block its PR flow.

## Scenario
A GHEC customer has a backlog of small, well-scoped bugs that never reach the top of anyone's list. Instead of letting them rot, they want to hand the clear ones to the Copilot cloud agent and have engineers review the results. You'll do exactly that on a small seeded repo with a known bug: write a crisp issue, assign it to Copilot, watch it open a draft PR and work in an ephemeral environment, then review and steer it to a correct, merged fix. You'll learn where the agent shines (small, bounded changes) and where human review stays essential.

## Setup
Run the provisioning entrypoint (Bash or PowerShell — both supported). `wth` is the documented command surface; it wraps the scripts in `modules/ghec/resources/provisioning/scripts/`.

```bash
# Bash
wth setup ch19 --org <org>
# or directly:
bash modules/ghec/resources/provisioning/scripts/setup.sh setup ch19 --org <org>
```
```powershell
# PowerShell
wth setup ch19 --org <org>
# or directly:
modules/ghec/resources/provisioning/scripts/setup.ps1 setup ch19 --org <org>
```

> `wth doctor ch19 --org <org>` runs first and **warns if the org looks EMU-managed** or if the Copilot cloud agent policy can't be confirmed. Heed it — the agent won't run on EMU repos.

**What setup creates** (all artifacts namespaced `wth-ch19-*`, idempotent, prefix-guarded teardown):
- A **small seeded buggy repo** **`wth-ch19-copilot-coding-agent`** (NOT Juice Shop — kept small so agent runs stay short and gradable): a tiny app with a **failing test** that pins a single, clear bug.
- A CI workflow that runs the test suite (so the agent's fix can be verified green).
- A **well-framed seeded issue** describing the bug, repro, and acceptance criteria — ready to assign to Copilot.
- A printed **Next steps** block (including how to add Copilot as a bypass actor if you enable branch protection).

> Re-running `setup` reconciles (create-if-absent). `wth teardown ch19 --org <org> --yes` removes only `wth-ch19-*` artifacts.

## Tasks

### Part A — Confirm eligibility
1. **Verify the policy.** Confirm the org has the **Copilot cloud agent** enabled (Org Settings → Copilot → Policies) and that your user has a Copilot license.
2. **Confirm non-EMU.** Ensure the repo is **not** in an EMU-managed enterprise. If `wth doctor ch19` flagged EMU, stop — this challenge can't run here.
3. **Open the seeded issue** and read its repro + acceptance criteria so you can judge the agent's output later.

### Part B — Delegate to the agent
4. **Assign the issue to Copilot.** On the seeded issue, add **Copilot** as the assignee (Assignees → Copilot). This triggers an agent session.
5. **Watch it start.** Within a minute or two the agent opens a **draft pull request** referencing the issue. Open it.
6. **Follow the session.** Read the agent's progress/session log on the PR (its plan, the files it's touching, the commands it runs in the ephemeral environment).

### Part C — Review the draft PR
7. **Read the diff critically.** Does the change actually fix the pinned bug? Does it touch anything it shouldn't? Check CI on the PR.
8. **Run/confirm the tests.** Confirm the previously failing test is now **green** in the PR's CI run.
9. **Leave a review.** Comment on a specific line with a concrete request (e.g., "handle the empty-input case too" or "add a test for X").

### Part D — Steer and iterate
10. **Request changes via the agent.** Use a PR review comment or `@`-mention to ask Copilot to revise. Confirm it pushes **new commits** to the same PR in response.
11. **Add missing context.** If the first attempt missed an edge case, update the issue/PR with the detail and let the agent iterate. Note how prompt quality changes the result.

### Part E — Gate, approve & merge
12. **(Optional) Add a branch protection / ruleset** on `main` requiring the CI check + a review. If the agent's PR is now blocked from updating, **add Copilot as a bypass actor** (or grant the needed permission) and document why.
13. **Mark ready & approve.** When the change is correct, take the PR out of draft, give it your approving review, and **merge** it.
14. **Confirm the fix landed.** On `main`, confirm the test suite is green and the issue auto-closed via the PR link.

### Part F — Reflect (write-up)
15. **Capture the boundary.** In `docs/AGENT-NOTES.md`, write a short reflection: what the agent did well, where human review was essential, and which kinds of issues you'd delegate vs not.

## Validation / Definition of Done
You are done when ALL of the following are true:
- [ ] You confirmed the **Copilot cloud agent is enabled** and the repo is **eligible (non-EMU)**.
- [ ] You **assigned the seeded issue to Copilot** and it opened a **draft pull request**.
- [ ] You read the agent's **session log** and **reviewed its diff** against the acceptance criteria.
- [ ] You **steered the agent** with at least one review comment and it pushed **new commits** in response.
- [ ] The **failing test is green** in the PR and the PR was **approved and merged** to `main`.
- [ ] You captured a short **reflection** on where the agent fits (and where human review stays essential).
- [ ] Coach conversation — which class of GitHub issues in your repos is well-defined enough that the Copilot coding agent could handle it unsupervised, and what review gate would you trust before merging its PR? Talk it through with your coach and connect it to a real project, task, or workflow you own.

> Coaches verify these via the automated hints in `COACH.md`.

## Stretch goals
- Hand the agent a **second, slightly larger** issue and observe how it scopes a bigger change.
- Add a **required ruleset** and walk the full **Copilot-as-bypass-actor** configuration end to end.
- Write the issue so well the agent needs **zero** follow-up — measure how much prompt quality reduces iteration.

## Reference links
- About Copilot cloud agent — https://docs.github.com/en/copilot/concepts/agents/cloud-agent/about-cloud-agent
- Managing access to Copilot cloud agent — https://docs.github.com/en/copilot/concepts/agents/cloud-agent/access-management
- Using Copilot to work on an issue — https://docs.github.com/en/copilot/using-github-copilot/coding-agent/using-copilot-to-work-on-an-issue
- Customizing or restricting Copilot cloud agent — https://docs.github.com/en/copilot/how-tos/use-copilot-agents/cloud-agent
- Managing GitHub Copilot policies in your organization — https://docs.github.com/en/copilot/managing-copilot/managing-github-copilot-in-your-organization/managing-policies-for-copilot-in-your-organization
- `gh pr` CLI manual — https://cli.github.com/manual/gh_pr
