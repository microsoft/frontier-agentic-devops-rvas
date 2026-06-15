# Challenge 3-05: Ship It — The Capstone

**Track:** Continuous Intelligence (Advanced)  
**Difficulty:** 🔴 Advanced  
**Estimated time:** 30 minutes  
**Prerequisites:** Track 2, completed ≥3 challenges; strong understanding of Track 3-01 through 3-04

---

## Background

Everything you've learned comes together here.

**Ship It** is the **end-to-end agentic pipeline**. Take an issue from discovery to resolution, entirely through autonomous workflows:

1. **Event**: An issue arrives or code changes (event trigger)
2. **Observe**: A workflow records what happened to `repo-memory` (producer)
3. **Triage**: A meta-workflow reads observations and creates a tracking issue (meta layer)
4. **Act**: A ChatOps workflow (`/fix` slash command) assigns the tracking issue to the Copilot coding agent
5. **Review**: Copilot fixes the issue, creates a PR
6. **Merge**: A final workflow merges the PR (or flags it for human review)

You've built pieces of this in 3-01, 3-02, 3-03, 3-04. Now **connect them into a working factory**.

This is the capstone. When you see this system run end-to-end, you'll understand what production agentic automation looks like.

**Why this matters:** This is not theory—it's a real pattern used in production. You'll walk away understanding how to orchestrate multiple AI agents into a coherent system.

---

## Goals

By the end of this challenge, your squad will:

1. ✅ Design and build a 3-5 workflow chain
2. ✅ Use all four techniques: events, repo-memory, meta-workflows, ChatOps
3. ✅ Successfully trigger the chain end-to-end
4. ✅ See an issue go from discovery to fix to PR to merge (or staged for merge)
5. ✅ Understand orchestration, not just individual workflows

---

## Challenge

Build a **factory pipeline** with at least 3 workflows:

### Workflow 1: Event Observer

Trigger: `on: issues: types: [opened]` OR `on: pull_request: types: [opened]`

Job: When an issue/PR arrives, record an observation to `repo-memory`:
```json
{
  "timestamp": "2026-05-28T14:54:00Z",
  "type": "issue_opened",
  "title": "...",
  "labels": [...],
  "urgency": "high|medium|low"
}
```

Output: `safe-outputs: noop` (data-collection only)

### Workflow 2: Triage & Track (Meta-workflow)

Trigger: `on: schedule: cron: "*/30 * * * *"` (every 30 min) OR `workflow_dispatch`

Job: 
1. Read recent observations from `repo-memory`
2. Analyze patterns (e.g., "3 bug reports in 30 minutes" → urgent)
3. Create a **tracking issue** in the repo with: "This batch of issues needs attention" + checkboxes for each issue

Output: `safe-outputs: create-issue`

**Key:** Use `lock-for-agent: true` to prevent duplicate issues.

### Workflow 3: ChatOps Fixer

Trigger: `on: issue_comment: types: [created]`

Pattern: When someone comments `/fix` on the tracking issue:

Job:
1. Parse the slash command
2. Extract the sub-issues from the tracking issue
3. `assign-to-agent: copilot` to fix them

Output: `safe-outputs: assign-to-agent`

### Optional Workflow 4: PR Merger

Trigger: `on: pull_request: types: [opened]`

Job: If PR was created by Copilot and all checks pass, auto-merge. Otherwise, add a "ready-for-review" label.

Output: `safe-outputs: add-labels`

---

## Success Criteria

- [ ] Workflow 1 (Observer) writes data to `repo-memory/observations/` with valid JSON
- [ ] Workflow 2 (Triage) reads from repo-memory and creates a tracking issue
- [ ] Workflow 2 includes `lock-for-agent: true` to prevent duplicates
- [ ] Workflow 3 (ChatOps) correctly handles `/fix` slash command
- [ ] Workflow 3 uses `assign-to-agent: copilot` (or compatible agent)
- [ ] All workflows compile and run without errors
- [ ] **End-to-end test**: Open an issue → Triage workflow creates tracking issue → Comment `/fix` on tracking issue → Copilot creates a PR (or attempts to)
- [ ] At least one workflow uses `repo-memory` for data passing
- [ ] At least one workflow uses `assign-to-agent`

---

## Tips & Hints

- **Start simple**: Build Workflow 1 (Observer) first. Get it writing to repo-memory. Celebrate when the file appears.
- **Then Workflow 2**: Read that data, create a tracking issue. Test in isolation.
- **Then Workflow 3**: Wire up the ChatOps trigger and `assign-to-agent` call. This is the "leap" moment.
- **Workflow 4 is optional**: If time is short, skip auto-merge. Just getting 1-3 working is a win.
- **Don't overthink urgency**: "High" if issue has label `bug`, "medium" if `feature`, "low" if `question`. Simple heuristics work.
- **Use `lock-for-agent: true` on Triage**: Prevents creating 5 duplicate tracking issues if multiple events fire.
- **Document the flow**: Draw a diagram or write comments in each workflow explaining what happens next.
- **Use `checkout: false`** where you can (Observer, Triage, ChatOps don't need code).

---

## References

- **repo-memory:** https://github.github.com/gh-aw/reference/repo-memory/
- **assign-to-agent:** https://github.github.com/gh-aw/reference/safe-outputs/#assign-to-agent
- **lock-for-agent:** https://github.github.com/gh-aw/reference/frontmatter/#lock-for-agent
- **slash-command pattern:** https://github.github.com/gh-aw/blog/2026-01-13-meet-the-workflows-interactive-chatops/
- **Workflow Generator (ChatOps example):** https://github.com/github/gh-aw/blob/main/.github/workflows/workflow-generator.md
- **Metrics Collector + Analyzer (producer-consumer chain):** https://github.com/github/gh-aw/blob/main/.github/workflows/metrics-collector.md

---

## Help

Stuck? Here's how to escalate:

- **"How do I wire up the workflows?"** → Each workflow is independent. Workflow 1 writes files, Workflow 2 reads files. No direct calls, just data in repo-memory.
- **"Workflow 2 isn't triggering?"** → Check the `on: schedule:` syntax. Try manual `workflow_dispatch` first.
- **"ChatOps `/fix` command not working?"** → Verify you're checking for `/fix` in `github.event.comment.body`. Show me your `if:` condition.
- **"Copilot not taking the assignment?"** → Check the `assign-to-agent:` syntax. Should be `safe-outputs: assign-to-agent: target: triggering, allowed: [copilot]`.
- **"Too much complexity?"** → Build just 2 workflows first (Observer + Triage). Get those working. Then add ChatOps.

Still stuck after 20 minutes? Raise your hand — this is the capstone and coaches expect it to be the hardest.

## 🔗 Extension: Multi-Repo Mode

**What it is:** A gh-aw workflow in one repo can create issues, PRs, or comments in a *different* repo using the `gh-proxy` tool. This is called multi-repo mode.

**When to use it:** Your Ship It factory writes tracking issues to a central `release-tracking` repo while fixes land in your feature repos. Or an org-health workflow in a meta-repo monitors all your team's repos.

**The syntax** — add to your workflow frontmatter:
```yaml
tools:
  gh-proxy:
    repos:
      - owner/other-repo    # must be listed explicitly — security allowlist
      - owner/another-repo  # add each target repo
```

**Security model:** The workflow's GitHub token must have `repo` scope for each listed repo. Repos not in the list are unreachable. This explicit allowlist is intentional — you can't accidentally write to repos you didn't list.

**Try it:** Extend your Ship It watcher to create a tracking issue in a second repo you own. Change the `repo-memory` write to target `owner/release-tracking` instead of the current repo.
