# GHAS Reference Fixtures

This directory contains GitHub Advanced Security (GHAS) configuration files that participants apply
to their shared org/Juice-Shop repository to light up GHAS scanning features during the hackathon.

These fixtures were originally maintained in the `frontier-ghas-hackathon` source repository and are
now vendored here so that repository can be retired.

## Files

| File | Purpose |
|------|---------|
| `github/workflows/codeql.yml` | CodeQL Analysis workflow — runs on push, PR, schedule, and manually. Scans JavaScript/TypeScript (Juice Shop's languages). |
| `github/codeql/codeql-config.yml` | CodeQL config — excludes compiled output (`app/build/`), source maps, test fixtures, and vendored JS to avoid parse errors and duplicate findings. |
| `github/dependabot.yml` | Dependabot config — weekly npm + GitHub Actions dependency checks, groups minor/patch updates, limits open PRs to 10. |

## How to apply

Copy these files into the `.github/` folder of the shared org repository (the one hosting your
Juice Shop instance):

```bash
# From the repo root — adjust <org>/<repo> to your hackathon org/repo
gh repo clone <org>/<repo> /tmp/target-repo
cp -r modules/ghas/resources/github/. /tmp/target-repo/.github/
cd /tmp/target-repo
git add .github/workflows/codeql.yml .github/codeql/codeql-config.yml .github/dependabot.yml
git commit -m "chore: add GHAS scanning configs (CodeQL + Dependabot)"
git push
```

Once pushed:

- **CodeQL alerts** appear under **Security → Code scanning alerts** in the target repository.
- **Dependabot alerts** appear under **Security → Dependabot alerts**.
- Copilot Autofix will offer suggested fixes for many CodeQL findings.

> **Note:** Juice Shop intentionally ships with vulnerable dependencies — a high alert count is
> expected and is the learning material, not a problem to immediately resolve.
