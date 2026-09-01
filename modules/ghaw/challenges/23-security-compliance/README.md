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

> [!TIP]
> [Bring your own repo](../../setup.md#bring-your-own-repo): configure the workflow with the real alert sources, severity thresholds, and SLA windows of a repo you own.

## Steps

1. Install and verify `gh aw` with the [GHAW setup guide](../../setup.md).

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

---

<details>
<summary>💡 Hints</summary>

"There are no Dependabot alerts in my test repo"
→ Add an intentionally vulnerable dependency (e.g., `lodash@4.17.4` is a known CVE), or mock the scan by giving the body an inline list of fake alerts and asking it to classify them.

"How does the agent access Dependabot alerts?"
→ Add `tools: github: toolsets: [security]` to the frontmatter for access to the security advisories API.

"I want it to comment on existing issues instead of opening new ones"
→ Replace `create-issue` with `add-comment` and add issue-lookup logic in the body: _"If an open issue already exists for this CVE, add a comment with the updated deadline. Only open a new issue if none exists."_

"Should this workflow also open PRs to fix vulnerabilities?"
→ That's an extension. For this activity, start with issue-creation-only (signal before action). Combine with Dependabot auto-merge or a separate fix workflow for the full automation.

</details>
