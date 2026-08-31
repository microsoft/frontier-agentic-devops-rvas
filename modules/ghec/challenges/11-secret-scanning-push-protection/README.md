# Ch11 — Secret Scanning & Push Protection

> Deliver secret scanning, push protection, custom patterns, and an auditable credential-triage path for an approved repository.

| | |
|---|---|
| Track | Security |
| Difficulty | Foundational *(per-track ramp)* |
| Duration | 105 min |
| Minimum input | An org + an org-owner token. *(All activities are org-scoped — no enterprise owner required.)* |
| App | juice-shop *(imported at pinned ref `v20.0.0`; see `docs/EXTERNAL-REPOS.md`)* |
| EMU compatible | yes |

## Prerequisites
- An organization you own (or org-owner rights) on GitHub Enterprise Cloud.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch11 --org <org>` (least-privilege; for this activity: `repo` + `admin:org` + `security_events`).
- Local tooling: `gh >= 2.x`, `git`, `jq` (run `modules/ghec/resources/provisioning/scripts/setup.sh doctor` to verify).
- GHAS note: secret scanning and push protection are free on public repos. Setup provisions the Juice Shop import as public, so no Code Security / Secret Protection license is required for Parts A–C and E. On private/internal repos these features need a paid license — `modules/ghec/resources/provisioning/scripts/setup.sh doctor` warns. Custom secret-scanning patterns (Part D) are different: they require GitHub Secret Protection on an organization-owned repo (GitHub Team or Enterprise) regardless of repo visibility, and are *not* part of the free public-repo feature set — see Part D.

## What you will deliver
- Enable secret scanning and push protection on a repository from both the UI and the API.
- Triage secret-scanning alerts: read the commit/blob location, then resolve each as revoked / false positive / used in tests.
- Experience push protection blocking a brand-new secret at `git push`, and exercise the bypass flow with a documented reason.
- Author a custom secret-scanning pattern (regex) and confirm it raises alerts on matching content.
- Audit push-protection bypasses via the API so a security team can see who pushed secrets anyway, and why.

## Scenario
A GHEC customer just discovered a hard-coded cloud key in a public repo — caught by an outside researcher, not by them. Leadership wants every credential already in history surfaced and triaged, and the *next* secret blocked before it lands on `main`. The provisioner imports OWASP Juice Shop and plants non-live, high-confidence test secrets (fake AWS keys, GitHub-style tokens) so secret scanning has real, partner-pattern material to detect.

> [!IMPORTANT]
> Use an approved customer target first. If you have a candidate repository, use it everywhere this guide says `ghec-ch11-juice-shop`, skip Setup, and skip the manifest steps — real history is the triage material. Otherwise use the fallback seeded repo below: it holds planted secrets, so it is a test repository only, never a delivery destination.
>
> Record the selected target, security owner, and next action.

## Sample test repository or environment
Skip if you brought your own repo.

```bash
# Bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch11 --org <org>
```
```powershell
# PowerShell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch11 --org <org>
```

Setup creates these resources (all names use the `ghec-ch11-*` prefix, and teardown is prefix-guarded):
- A public repo `ghec-ch11-juice-shop` — OWASP Juice Shop imported at pinned ref `v20.0.0` (pulled from the official source, never vendored).
- Planted high-confidence test secrets committed across history — a fake AWS key pair in an early commit and a GitHub-style token (`ghp_…`) in a later commit. All planted secrets are non-live / synthetic.
- A small `SECRETS-MANIFEST.md` documenting which fake secrets were planted and where.
- A `feature/leaky-config` branch carrying one fresh planted secret to exercise push protection.
- A printed Next steps block.

## Tasks

### Part A — Enable secret scanning
1. In `ghec-ch11-juice-shop` → Settings → Code security, enable Secret scanning and Push protection. (On a public repo these may already be on — confirm both toggles read "Enabled".)
2. Confirm via API that the features are active:
   ```bash
   gh api repos/<org>/ghec-ch11-juice-shop --jq '.security_and_analysis'
   ```
   You should see `secret_scanning` and `secret_scanning_push_protection` reading `enabled`.
3. Open `SECRETS-MANIFEST.md` so you know which planted secrets to expect — reconcile against the alert list in Part B.

### Part B — Triage the alert backlog
4. Go to Security → Secret scanning and review every alert. Each planted secret (AWS key, GitHub token, etc.) should have raised one. Cross-check against `SECRETS-MANIFEST.md`.
5. Open the AWS-key alert and note its secret type, the commit/file/line where it was introduced, and whether GitHub attempted validity verification (these planted secrets are non-live).
6. List alerts via API and confirm the count and types match the manifest:
   ```bash
   gh api repos/<org>/ghec-ch11-juice-shop/secret-scanning/alerts --jq '.[] | {number, secret_type, state}'
   ```
7. Resolve every alert with an explicit reason via the UI Close as… menu (or the API) — `used_in_tests` or `revoked` is appropriate for the synthetic planted secrets:
   ```bash
   gh api -X PATCH repos/<org>/ghec-ch11-juice-shop/secret-scanning/alerts/<n> \
     -f state=resolved -f resolution=used_in_tests \
     -f resolution_comment="Planted non-live test secret — see SECRETS-MANIFEST.md"
   ```

### Part C — Push protection in action
8. Check out `feature/leaky-config` locally (`gh repo clone <org>/ghec-ch11-juice-shop`), or add your own line containing a fresh fake `AKIA…` key to a file, commit, and `git push`. Push protection should reject the push and print the offending secret type and location.
9. Note that push protection tells you exactly which line to remove. Remove the secret, amend/commit, and push cleanly to confirm the block is content-specific, not branch-wide.
10. Re-introduce a fake secret and push again; when blocked, follow the bypass path with a reason (e.g. *"used in tests"*) so a bypass event is recorded — this is the audit trail you'll inspect in Part E.

### Part D — A custom pattern
> Licensing note: Custom secret-scanning patterns require GitHub Secret Protection on an organization-owned repository (GitHub Team or Enterprise) — unlike Parts A–C, not free on public repos. If your org lacks it, treat Part D as read-only/awareness and complete the remaining parts.
11. In Settings → Advanced Security → Secret Protection → Custom patterns, create a pattern matching an org-specific token shape GitHub doesn't ship — e.g. `GHEC_KEY_[A-Z0-9]{20}`. Give it a name, the regex, and a test string.
12. Commit a line matching your pattern (e.g. `GHEC_KEY_ABCDEFGH012345678901`) to a new branch and confirm a new alert appears (allow a short delay for the pattern to publish).

### Part E — Audit the bypasses
13. List push-protection bypasses so a security team can see who pushed a secret anyway and why:
    ```bash
    gh api repos/<org>/ghec-ch11-juice-shop/secret-scanning/alerts \
      --jq '.[] | select(.push_protection_bypassed==true) | {number, secret_type, by: .push_protection_bypassed_by.login}'
    ```
14. Write a one-paragraph triage summary as an issue on the repo: how many secrets were found, how each was resolved, that push protection blocked a fresh secret, and who bypassed it and why.

## Reference links
- About secret scanning — https://docs.github.com/en/code-security/secret-scanning/about-secret-scanning
- Configuring secret scanning for your repositories — https://docs.github.com/en/code-security/secret-scanning/enabling-secret-scanning-features/enabling-secret-scanning-for-your-repository
- Protecting pushes with secret scanning — https://docs.github.com/en/code-security/secret-scanning/introduction/about-push-protection
- Managing alerts from secret scanning — https://docs.github.com/en/code-security/secret-scanning/managing-alerts-from-secret-scanning
- Defining custom patterns for secret scanning — https://docs.github.com/en/code-security/secret-scanning/using-advanced-secret-scanning-and-push-protection-features/custom-patterns/defining-custom-patterns-for-secret-scanning
- Secret scanning REST API — https://docs.github.com/en/rest/secret-scanning/secret-scanning
