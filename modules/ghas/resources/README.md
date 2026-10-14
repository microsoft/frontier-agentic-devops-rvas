# GHAS resources

This directory holds two kinds of content: the GitHub Advanced Security
configs and evidence templates you apply to a real repository, and the
provisioning scripts that create disposable admin test repositories for the
Admin & Governance activities.

## Files

| File | Purpose |
|------|---------|
| `github/workflows/codeql.yml` | Runs CodeQL on pushes, PRs, a weekly schedule, and manual dispatch. Scans JavaScript and TypeScript. |
| `github/codeql/codeql-config.yml` | Excludes compiled output (`app/build/`), source maps, test fixtures, and vendored JavaScript to prevent parse errors and duplicate findings. |
| `github/dependabot.yml` | Checks npm and GitHub Actions dependencies weekly, groups minor and patch updates, and limits open PRs to 10. |
| `ghas-governance-practice.template.md` | Optional fields for decisions missing from existing GitHub work. |
| `start-remediation.md` | Shared finding and ownership checks used inside each remediation case. |
| `license-exception.yml` | Optional time-bound legal intake for the existing dependency-review gate. |
| `provisioning/README.md` | Lists the four admin test repositories, which repository each provisioner uses, and provision, status, and teardown commands. |
| `provisioning/challenges/` | Holds separate Bash and PowerShell provisioners for admin activities 01 through 06. |

## How to apply

Activity S00's `setup.sh` or `setup.ps1` applies these files. For manual setup, copy
them into the org-owned Juice Shop repository's `.github/` directory:

```bash
# From the curriculum repo root. Adjust <org>/<repo> to your delivery session org/repo.
gh repo clone <org>/<repo> /tmp/target-repo
cp -r modules/ghas/resources/github/. /tmp/target-repo/.github/
cd /tmp/target-repo
git add .github/workflows/codeql.yml .github/codeql/codeql-config.yml .github/dependabot.yml
git commit -m "chore: add GHAS scanning configs (CodeQL + Dependabot)"
git push
```

> If the setup script created the target repo, npm
> manifests live at the repository root. The script changes
> `.github/dependabot.yml` from `directory: "/app"` to `directory: "/"`
> automatically. Make the same change for a manual direct import.

Once pushed:

- CodeQL alerts appear under Security → Code scanning alerts in the target repository.
- Dependabot alerts appear under Security → Dependabot alerts.
- Copilot Autofix will offer suggested fixes for many CodeQL findings.

> Juice Shop intentionally includes vulnerable dependencies.
> A high alert count is expected and does not require immediate resolution.

## Facilitator background: Codename MDASH ("multi-model agentic scanning harness")

CodeQL is the baseline for this module. It provides GitHub-native code scanning
and remains the control used by every activity. Activity 3, step 1 has learners
compare CodeQL coverage against MDASH; this section gives facilitators the
deeper background behind that exercise.

Codename MDASH (short for "multi-model agentic scanning harness") is a
separate Microsoft Defender capability currently in preview. It uses
coordinated AI agents to inspect source code and reports its findings through
Microsoft Security Exposure Management. Microsoft documents a GitHub connector
for onboarding repositories and running on-demand scans.

MDASH complements CodeQL; it doesn't replace it. Current Microsoft
documentation doesn't state that MDASH findings appear as native GitHub
code-scanning alerts or that MDASH consumes CodeQL alerts. Keep the two result
sets separate unless Microsoft documents that integration.

- [Codename MDASH overview](https://learn.microsoft.com/en-us/security-exposure-management/ai-code-security-overview)
- [Create a GitHub connector](https://learn.microsoft.com/en-us/security-exposure-management/create-github-connector)

## Facilitator background: Microsoft Defender for Cloud (production-risk correlation)

Activity 6's step 3b teaches this correlation as part of scoping a campaign's
alert set. What follows is the deeper background a facilitator may need.

Microsoft Defender for Cloud can correlate the code scanning and Dependabot
alerts this module already produces with deployment and runtime-risk context,
such as internet exposure or sensitive-data handling. It reads GitHub's
existing alerts; it doesn't replace CodeQL and doesn't run its own code
analysis. Current Microsoft documentation doesn't describe secret-scanning
enrichment, so treat that alert type as outside this integration.

Defender for Cloud doesn't create or publish a campaign for you. A human still
creates and publishes the campaign in GitHub; Defender for Cloud only supplies
the `has:deployment` and runtime-risk filters that can shape which alerts the
campaign targets.

Artifact attestations are optional context here. Skip them unless a learner
asks a question that needs that detail.

Setup needs Defender Cloud Security Posture Management (CSPM) enabled on the
subscription, Azure Security Admin permissions, and a GitHub organization
owner to create the connector. This stays reference-only for the module: the
official sandbox isn't ready for a live workshop walkthrough.

> **Facilitator note:** Microsoft's overview and deploy pages describe the
> GitHub connector and this GHAS integration as generally available, but
> GitHub's own linked-artifacts documentation may still label its Microsoft
> Defender for Cloud (MDC) data source as preview. Mention this GA-versus-preview
> gap to co-facilitators only; keep it out of learner-facing activity text.

- [GitHub Advanced Security integration with Microsoft Defender for Cloud](https://learn.microsoft.com/en-us/azure/defender-for-cloud/github-advanced-security-overview)
- [Deploy the GitHub Advanced Security integration](https://learn.microsoft.com/en-us/azure/defender-for-cloud/github-advanced-security-deploy)
- [Prioritizing Dependabot and code scanning alerts using production context](https://docs.github.com/en/code-security/tutorials/secure-your-organization/prioritize-alerts-in-production-code)

## Admin test repositories

Start with [`provisioning/README.md`](provisioning/README.md). The admin track uses
four separate provisioners so each teardown affects only its own files and
repositories. Activities 01 and 06 share one repository. Activity 03 uses one CodeQL
repository through coverage and merge enforcement. Activities 02 and 05 use their own repositories.
