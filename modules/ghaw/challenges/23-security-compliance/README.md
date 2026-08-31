Track: Production Patterns (Advanced 🟣)
Estimated time: 30 minutes
Tier: Bonus

---

## Background

Security Compliance runs on a schedule, tracks vulnerability SLA deadlines by severity, and opens issues when configured thresholds are met. It reports possible policy violations. The team still owns remediation.

The workflow stores SLA windows, escalation rules, and severity thresholds in version-controlled configuration.

Source: [`github/gh-aw/.github/workflows/security-compliance.md`](https://github.com/github/gh-aw/blob/main/.github/workflows/security-compliance.md)

## Behavior

- Runs on a scheduled cron (daily or weekly)
- Scans for open vulnerabilities (Dependabot alerts, GHSA advisories, or custom sources)
- Classifies by severity (critical, high, medium, low)
- Tracks time-to-remediate against configured SLA windows
- Opens structured issues for any vulnerability at or approaching deadline

> [!IMPORTANT]
> Bring your own repo (do this first)
>
> Use a repository in an organization you control. Choose one with Dependabot alerts, dependency risk, or security SLAs that need visible tracking.
>
> - Have a candidate repo? Use it everywhere this guide references the sample repo, and configure the workflow with that repo's real alert sources, severity thresholds, SLA windows, and escalation targets.
> - No suitable repo yet? Use the provided sample repo from setup as the safe practice target.
>
> Tell the facilitator which repository and policy you chose.

## Steps

1. Install [`gh aw`](https://github.com/github/gh-aw) (if not already done):
   ```bash
   curl -sL https://raw.githubusercontent.com/github/gh-aw/main/install-gh-aw.sh | bash
   ```

2. Pull the production workflow:
   ```bash
   gh aw add-wizard https://github.com/github/gh-aw/blob/main/.github/workflows/security-compliance.md
   ```

3. Read the SLA definitions in the frontmatter or body. Note how each severity maps to days-to-fix.

4. Customise the SLA windows, severity thresholds, and notification targets for your repo's policy.

5. Compile:
   ```bash
   gh aw compile security-compliance
   ```

6. Enable [Dependabot alerts](https://docs.github.com/en/code-security/dependabot/dependabot-alerts/about-dependabot-alerts) on the repository (Settings > Security > Dependabot alerts) if needed.

7. Trigger it manually and inspect the result.

## Adapt it

- Set the SLA windows in the body, for example: `"Critical: 3 days, High: 14 days, Medium: 30 days, Low: 90 days"`. Use the organization's actual policy.
- Change the severity thresholds if the repository tracks only critical and high findings.
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
- [ ] Using a project, task, or workflow you own, compare current vulnerability SLA tracking with agent-filed issues and define how to prevent alert noise.

---

<details>
<summary>💡 Hints</summary>

"There are no Dependabot alerts in my test repo"
→ Add an intentionally vulnerable dependency (e.g., `lodash@4.17.4` is a known CVE), or mock the scan by giving the body an inline list of fake alerts and asking it to classify them.

"How does the agent access Dependabot alerts?"
→ Add `tools: github: toolsets: [security]` to the frontmatter for access to the security advisories API.

"I want it to comment on existing issues instead of opening new ones"
→ Replace `create-issue` with `add-comment` and add issue-lookup logic in the body: _"If an open issue already exists for this CVE, add a comment with the updated deadline. Only open a new issue if none exists."_

"What's the difference between a Dependabot alert and a GHSA advisory?"
→ Dependabot alerts apply to one repository and its dependencies. The [GitHub Advisory Database](https://docs.github.com/en/code-security/security-advisories/working-with-global-security-advisories-from-the-github-advisory-database/about-the-github-advisory-database) is global. Configure the agent for the source you need.

"Should this workflow also open PRs to fix vulnerabilities?"
→ That's an extension. For this activity, start with issue-creation-only (signal before action). Combine with Dependabot auto-merge or a separate fix workflow for the full automation.

</details>
