# GHAS Reference Fixtures

This directory contains GitHub Advanced Security (GHAS) configuration files that participants apply
to the org-owned Juice Shop repository provisioned in Activity S00 to enable GHAS scanning
features during the delivery session.

These fixtures were moved here from a retired predecessor repository. Keeping
them with the curriculum makes the setup reproducible without another source
repository.

## Files

| File | Purpose |
|------|---------|
| `github/workflows/codeql.yml` | CodeQL Analysis workflow — runs on push, PR, schedule, and manually. Scans JavaScript/TypeScript (Juice Shop's languages). |
| `github/codeql/codeql-config.yml` | CodeQL config — excludes compiled output (`app/build/`), source maps, test fixtures, and vendored JS to avoid parse errors and duplicate findings. |
| `github/dependabot.yml` | Dependabot config — weekly npm + GitHub Actions dependency checks, groups minor/patch updates, limits open PRs to 10. |
| `ghas-governance-practice.template.md` | Progressive customer-safe template for GHAS configuration and ownership, a security findings register, prevention patterns, response decisions, and operating cadence. |

## How to apply

Activity S00's `setup.sh`/`setup.ps1` automation applies these files for you. If you need to apply
them manually, copy them into the `.github/` folder of the org-owned Juice Shop repository:

```bash
# From the curriculum repo root — adjust <org>/<repo> to your delivery session org/repo
gh repo clone <org>/<repo> /tmp/target-repo
cp -r modules/ghas/resources/github/. /tmp/target-repo/.github/
cd /tmp/target-repo
git add .github/workflows/codeql.yml .github/codeql/codeql-config.yml .github/dependabot.yml
git commit -m "chore: add GHAS scanning configs (CodeQL + Dependabot)"
git push
```

> Note: If the target repo is a direct Juice Shop import created by the setup script, npm
> manifests live at repository root. The setup script adjusts `.github/dependabot.yml` from
> `directory: "/app"` to `directory: "/"` automatically. Make the same edit when applying these
> files manually to a direct Juice Shop import.

Once pushed:

- CodeQL alerts appear under Security → Code scanning alerts in the target repository.
- Dependabot alerts appear under Security → Dependabot alerts.
- Copilot Autofix will offer suggested fixes for many CodeQL findings.

> Note: Juice Shop intentionally ships with vulnerable dependencies — a high alert count is
> expected and is the learning material, not a problem to immediately resolve.
