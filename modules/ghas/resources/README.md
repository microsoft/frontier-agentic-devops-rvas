# GHAS Reference Fixtures

This directory contains GitHub Advanced Security configuration, evidence
templates, and the isolated Admin & Governance fixtures.

## Files

| File | Purpose |
|------|---------|
| `github/workflows/codeql.yml` | Runs CodeQL on pushes, PRs, a weekly schedule, and manual dispatch. Scans JavaScript and TypeScript. |
| `github/codeql/codeql-config.yml` | Excludes compiled output (`app/build/`), source maps, test fixtures, and vendored JavaScript to prevent parse errors and duplicate findings. |
| `github/dependabot.yml` | Checks npm and GitHub Actions dependencies weekly, groups minor and patch updates, and limits open PRs to 10. |
| `ghas-governance-practice.template.md` | Records GHAS scope and ownership, findings, prevention patterns, response decisions, and operating cadence. |
| `provisioning/README.md` | Lists the four admin fixtures, their repository boundaries, and provision, status, and teardown commands. |
| `provisioning/challenges/` | Holds separate Bash and PowerShell provisioners for admin activities 01 through 06. |

## How to apply

Activity S00's `setup.sh` or `setup.ps1` applies these files. For manual setup, copy
them into the org-owned Juice Shop repository's `.github/` directory:

```bash
# From the curriculum repo root — adjust <org>/<repo> to your delivery session org/repo
gh repo clone <org>/<repo> /tmp/target-repo
cp -r modules/ghas/resources/github/. /tmp/target-repo/.github/
cd /tmp/target-repo
git add .github/workflows/codeql.yml .github/codeql/codeql-config.yml .github/dependabot.yml
git commit -m "chore: add GHAS scanning configs (CodeQL + Dependabot)"
git push
```

> **Direct Juice Shop imports:** If the setup script created the target repo, npm
> manifests live at the repository root. The script changes
> `.github/dependabot.yml` from `directory: "/app"` to `directory: "/"`
> automatically. Make the same change for a manual direct import.

Once pushed:

- CodeQL alerts appear under Security → Code scanning alerts in the target repository.
- Dependabot alerts appear under Security → Dependabot alerts.
- Copilot Autofix will offer suggested fixes for many CodeQL findings.

> **Expected alerts:** Juice Shop intentionally includes vulnerable dependencies.
> A high alert count is expected and does not require immediate resolution.

## Admin fixtures

Start with [`provisioning/README.md`](provisioning/README.md). The admin track uses
four separate fixtures so each teardown has a narrow ownership boundary. Activities
01 and 06 share one repository. Activities 03 and 04 share the prepared CodeQL
pull request. Activities 02 and 05 use their own repositories.
