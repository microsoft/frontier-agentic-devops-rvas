**Track:** Production Patterns (Advanced 🟣)
**Estimated time:** 30 minutes
**Tier:** Bonus

---

## Background

Security vulnerabilities don't respect your sprint schedule. They land in your dependency tree on a Tuesday and quietly age past their SLA window while the team ships features. Security Compliance encodes your vulnerability policy as an agentic workflow: it scans on a schedule, tracks SLA deadlines by severity, and opens deadline-aware issues before anything slips.

This is security-as-code — your SLAs, escalation logic, and severity thresholds live in the workflow file alongside your other infrastructure.

Source: `github/gh-aw/.github/workflows/security-compliance.md`

## What It Does

- Runs on a scheduled cron (daily or weekly)
- Scans for open vulnerabilities (Dependabot alerts, GHSA advisories, or custom sources)
- Classifies by severity (critical, high, medium, low)
- Tracks time-to-remediate against configured SLA windows
- Opens structured issues for any vulnerability at or approaching deadline

## What You'll Do

1. **Install gh aw** (if not already done):
   ```bash
   curl -sL https://raw.githubusercontent.com/github/gh-aw/main/install-gh-aw.sh | bash
   ```

2. **Pull the production workflow**:
   ```bash
   gh aw add-wizard https://github.com/github/gh-aw/blob/main/.github/workflows/security-compliance.md
   ```

3. **Read the SLA definitions** in the frontmatter or body — note how severity maps to days-to-fix.

4. **Customise** the SLA windows, severity thresholds, and notification targets for your repo's policy.

5. **Compile**:
   ```bash
   gh aw compile .github/workflows/security-compliance.md
   ```

6. **Enable Dependabot alerts** on your repo (Settings > Security > Dependabot alerts) if not already enabled — give the workflow something to find.

7. **Manually trigger** and check if it surfaces any alerts.

## Customize It

- Set your SLA windows in the body: `"Critical: 3 days, High: 14 days, Medium: 30 days, Low: 90 days"` — or whatever your org policy says
- Change severity thresholds — maybe you only care about critical and high in this repo
- Add assignees or team mentions to the `create-issue` output: `"Assign all critical issues to @security-team"`
- Adjust the schedule: daily for high-velocity repos, weekly for smaller projects

## Success Criteria

- [ ] `.github/workflows/security-compliance.md` exists with valid frontmatter
- [ ] `schedule: cron` trigger is set
- [ ] SLA windows are defined in the body (severity → days)
- [ ] `safe-outputs: create-issue` is declared
- [ ] `.lock.yml` compiles without errors
- [ ] Manually triggered run either: opens issues for real alerts, or reports "no violations found" clearly
- [ ] Issues (if opened) include: CVE/advisory ID, severity, days remaining, package name
- [ ] Coach conversation — how does your team track vulnerabilities and SLA deadlines today, and where would deadline-aware agent-filed issues close a real gap versus create alert fatigue you would regret? Talk it through with your coach and connect it to a real project, task, or workflow you own.

---

<details>
<summary>💡 Hints</summary>

**"There are no Dependabot alerts in my test repo"**
→ Add an intentionally vulnerable dependency (e.g., `lodash@4.17.4` is a known CVE), or mock the scan by giving the body an inline list of fake alerts and asking it to classify them.

**"How does the agent access Dependabot alerts?"**
→ Use `tools: github: toolsets: [security]` — this gives the agent access to the security advisories API. Include that in your frontmatter.

**"I want it to comment on existing issues instead of opening new ones"**
→ Replace `create-issue` with `add-comment` and add issue-lookup logic in the body: _"If an open issue already exists for this CVE, add a comment with the updated deadline. Only open a new issue if none exists."_

**"What's the difference between a Dependabot alert and a GHSA advisory?"**
→ Dependabot alerts are per-repo (your dependencies). GHSA is the global advisory database. The agent can work with both — scope it to whichever is relevant.

**"Should this workflow also open PRs to fix vulnerabilities?"**
→ That's an extension. For this challenge, start with issue-creation-only (signal before action). Combine with Dependabot auto-merge or a separate fix workflow for the full automation.

</details>

---

<a href="https://github.com/microsoft/frontier-ghaw-hackathon/blob/main/challenges/track-4-production-patterns/4-07-security-compliance/Student/README.md" class="btn btn--primary">📘 Student Guide</a>
<a href="https://github.com/microsoft/frontier-ghaw-hackathon/blob/main/challenges/track-4-production-patterns/4-07-security-compliance/Coach/README.md" class="btn btn--ghost">🎓 Coach Guide</a>
