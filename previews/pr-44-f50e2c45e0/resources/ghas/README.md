# GHAS resources

This directory holds GitHub Advanced Security configs and evidence templates
for a real repository. It also holds provisioning scripts that create disposable
admin test repositories for the Admin & Governance activities.

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

CodeQL is the baseline for this module. Activity 3, step 1 has learners compare
CodeQL coverage against MDASH, a separate preview capability inside Microsoft
Defender that uses coordinated AI agents to inspect source code. `ghas-admin-08`
is the full onboarding and operation activity: preview enrollment, Microsoft
Foundry setup, Defender unified RBAC, the GitHub connector, and triage. Send
facilitators there for anything beyond the coverage comparison.

MDASH complements CodeQL; it doesn't replace it, and current Microsoft
documentation doesn't state that MDASH consumes CodeQL alerts or publishes as
native GitHub code-scanning alerts.

- [Codename MDASH overview](https://learn.microsoft.com/en-us/security-exposure-management/ai-code-security-overview)
- [`ghas-admin-08` README](../../challenge.html?id=ghas-admin-08)

## Facilitator background: Microsoft Defender for Cloud (production-risk correlation)

Activity 6's step 3b teaches a synthetic version of this correlation as its
no-access fallback. `ghas-admin-07` is the full live activity: Defender CSPM,
the Azure-portal GitHub connector, an AKS workload, and a real campaign scoped
with `has:deployment` and runtime-risk filters. Send facilitators there for
setup detail; this section only covers what's unique to facilitating it.

Defender for Cloud reads GitHub's existing code scanning and Dependabot
alerts; it doesn't run its own code analysis and doesn't create or publish a
campaign. Current Microsoft documentation doesn't describe secret-scanning
enrichment, so treat that alert type as outside this integration. Artifact
attestations are optional context — skip them unless a learner asks.

> **Facilitator note:** Microsoft's overview and deploy pages describe the
> GitHub connector and this GHAS integration as generally available, but
> GitHub's own linked-artifacts documentation may still label its Microsoft
> Defender for Cloud (MDC) data source as preview. Mention this GA-versus-preview
> gap to co-facilitators only; keep it out of learner-facing activity text.

- [GitHub Advanced Security integration with Microsoft Defender for Cloud](https://learn.microsoft.com/en-us/azure/defender-for-cloud/github-advanced-security-overview)
- [`ghas-admin-07` README](../../challenge.html?id=ghas-admin-07)

## Admin test repositories

Start with [`provisioning/README.md`](provisioning/README.md). The admin track uses
four separate provisioners so each teardown affects only its own files and
repositories. Activities 01 and 06 share one repository. Activity 03 uses one CodeQL
repository through coverage and merge enforcement. Activities 02 and 05 use their own repositories.
