# Ch11 — Secret Scanning & Push Protection

> By the end of this challenge you can turn on GitHub secret scanning, triage real leaked-credential alerts, block new secrets at `git push` with push protection, and wire up a custom pattern and a bypass-audit — all on a public OWASP Juice Shop repo seeded with high-confidence planted secrets.

| | |
|---|---|
| **Track** | Security |
| **Difficulty** | Foundational *(per-track ramp)* |
| **Duration** | ~4 hrs total, multi-session |
| **Minimum input** | An **org** + an **org-owner token**. *(All challenges are org-scoped — no enterprise owner required.)* |
| **App** | juice-shop *(imported at pinned ref `v20.0.0`; see `docs/EXTERNAL-REPOS.md`)* |
| **EMU compatible** | yes |

## Prerequisites
- An organization you own (or org-owner rights) on GitHub Enterprise Cloud.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch11 --org <org>` (least-privilege; for this challenge: `repo` + `admin:org` + `security_events`).
- Local tooling: `gh >= 2.x`, `git`, `jq` (run `modules/ghec/resources/provisioning/scripts/setup.sh doctor` to verify).
- **GHAS note:** **secret scanning** and **push protection** are **free on public repos**. Setup provisions the Juice Shop import as **public**, so no Code Security / Secret Protection license is required for Parts A–C and E. On private/internal repos these features need a paid license — `modules/ghec/resources/provisioning/scripts/setup.sh doctor` warns. **Custom secret-scanning patterns (Part D) are different:** they require **GitHub Secret Protection** on an organization-owned repo (GitHub Team or Enterprise) regardless of repo visibility, and are *not* part of the free public-repo feature set — see Part D.

## Scenario objectives
By completing this challenge you will:
- Enable **secret scanning** and **push protection** on a repository from both the UI and the API.
- Triage **secret-scanning alerts**: read the commit/blob location, then resolve each as revoked / false positive / used in tests.
- Experience **push protection** blocking a brand-new secret at `git push`, and exercise the **bypass** flow with a documented reason.
- Author a **custom secret-scanning pattern** (regex) and confirm it raises alerts on matching content.
- Audit **push-protection bypasses** via the API so a security team can see who pushed secrets anyway, and why.

## Scenario
A GHEC customer just discovered a hard-coded cloud key in a public repo — caught by an outside researcher, not by them. Leadership wants two guarantees: (1) every credential already sitting in history is surfaced and triaged, and (2) the *next* secret never lands on `main` in the first place. You'll prove both on a deliberately leaky app: the provisioner imports OWASP Juice Shop and plants a set of **non-live, high-confidence test secrets** (fake AWS keys, GitHub-style tokens) so secret scanning has real, partner-pattern material to detect — Juice Shop's own app secrets are internal and won't reliably trip detection on their own.

> [!IMPORTANT]
> **Bring your own outcome (do this first)**
>
> This challenge is most valuable when the result *outlives the delivery session*. **Pick a real repository your organization owns** — ideally a public one, or a private/internal one if you have GitHub Secret Protection — and complete every task on **that** repo. You leave with secret scanning, push protection, a custom pattern, and a triage trail genuinely standing up on a project you care about.
>
> - **Have a candidate repo?** Use it everywhere this guide says `ghec-ch11-juice-shop`. Skip the Setup step below entirely. You already have real history to triage — no planted secrets needed.
> - **No suitable repo (or want a safe sandbox)?** Use the fallback below: we import OWASP Juice Shop with non-live planted secrets so you can practice without risk.
>
> Tell your coach which path you took. "Bring your own" is the goal; the sample is the fallback.

## Setup (fallback sample)
Skip this if you brought your own repo. Otherwise run the provisioning entrypoint (Bash or PowerShell — both supported).

```bash
# Bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch11 --org <org>
```
```powershell
# PowerShell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch11 --org <org>
```

**What setup creates** (all artifacts namespaced `ghec-ch11-*`, idempotent, prefix-guarded teardown):
- A **public** repo **`ghec-ch11-juice-shop`** — OWASP Juice Shop imported at pinned ref **`v20.0.0`** (pulled from the official source, never vendored into this repo).
- **Planted high-confidence test secrets** committed across **history** so secret scanning has partner-pattern material to detect — for example a fake AWS access key (`AKIA…` paired with a fake secret access key) in an early commit and a GitHub-style token (`ghp_…`) in a later commit. **All planted secrets are non-live / synthetic** and exist only to trigger detection.
- A small **`SECRETS-MANIFEST.md`** in the repo documenting which fake secrets were planted and where, so coaches and students can reconcile expected detections without guessing.
- A `feature/leaky-config` **branch** carrying one fresh planted secret you'll use to exercise push protection.
- A printed **Next steps** block telling you where to start.


## Tasks
> Throughout, **`ghec-ch11-juice-shop` is the fallback sample**. If you brought your own repo, substitute its name in every command and skip the manifest steps (your real commit history is the material to triage).

### Part A — Enable secret scanning
1. **Turn on the features.** In `ghec-ch11-juice-shop` → **Settings → Code security**, enable **Secret scanning** and **Push protection**. (On a public repo these may already be on by default — confirm both toggles read "Enabled".)
2. **Confirm via API** that the features are active:
   ```bash
   gh api repos/<org>/ghec-ch11-juice-shop --jq '.security_and_analysis'
   ```
   You should see `secret_scanning` and `secret_scanning_push_protection` reading `enabled`.
3. **Read the manifest.** Open `SECRETS-MANIFEST.md` so you know exactly which planted secrets to expect — you'll reconcile this against the alert list in Part B.

### Part B — Triage the alert backlog
4. **Open the alert list.** Go to **Security → Secret scanning** and review every alert. Each planted partner-pattern secret (AWS key, GitHub token, etc.) should have raised one. Cross-check against `SECRETS-MANIFEST.md`.
5. **Inspect one alert in depth.** Open the AWS-key alert and note its **secret type**, the **commit** and **file/line** where it was introduced, and whether GitHub attempted **validity verification** (partner secrets can be checked for activeness — these planted ones are non-live).
6. **List alerts via API** and confirm the count and types match the manifest:
   ```bash
   gh api repos/<org>/ghec-ch11-juice-shop/secret-scanning/alerts --jq '.[] | {number, secret_type, state}'
   ```
7. **Resolve every alert** with an explicit reason. Use the UI **Close as…** menu (or the API) and choose the correct resolution per secret — for the planted test secrets, **`used_in_tests`** or **`revoked`** is appropriate since they're synthetic:
   ```bash
   gh api -X PATCH repos/<org>/ghec-ch11-juice-shop/secret-scanning/alerts/<n> \
     -f state=resolved -f resolution=used_in_tests \
     -f resolution_comment="Planted non-live test secret — see SECRETS-MANIFEST.md"
   ```

### Part C — Push protection in action
8. **Try to push a new secret.** Check out `feature/leaky-config` locally (`gh repo clone <org>/ghec-ch11-juice-shop`), or add your own line containing a fresh fake `AKIA…` key to a file, commit, and `git push`. Push protection should **reject the push** at the command line and print the offending secret type and location.
9. **Read the block message.** Note that push protection tells you exactly which line to remove. Remove the secret, amend/commit, and push cleanly to confirm the block is content-specific, not branch-wide.
10. **Exercise a deliberate bypass.** Re-introduce a fake secret and push again; when blocked, follow the **bypass** path (the prompt lets you push anyway with a reason — *"it's a false positive"* / *"used in tests"* / *"will fix later"*). Choose a reason and complete the bypass so a **bypass event** is recorded. (You are intentionally creating an audit trail to inspect in Part E.)

### Part D — A custom pattern
> **Licensing note:** Custom secret-scanning patterns require **GitHub Secret Protection** enabled on an organization-owned repository (GitHub Team or Enterprise). Unlike Parts A–C, this capability is *not* free on public repos — if your org doesn't have Secret Protection, the **Custom patterns** option won't appear. If you can't enable it, treat Part D as read-only/awareness and still complete the remaining parts.
11. **Add a custom secret-scanning pattern.** In **Settings → Advanced Security → Secret Protection → Custom patterns** (older UIs label this section **Code security**), create a pattern that matches an org-specific token shape GitHub doesn't ship out of the box — for example an internal key like `GHEC_KEY_[A-Z0-9]{20}`. Give it a name, the regex, and a test string.
12. **Trigger it.** Commit a line containing a value matching your pattern (e.g. `GHEC_KEY_ABCDEFGH012345678901`) to a new branch and confirm a **new alert** appears for your custom pattern (custom-pattern scans run after the pattern is published — allow a short delay).

### Part E — Audit the bypasses
13. **List push-protection bypasses** so a security team can see who pushed a secret anyway and why:
    ```bash
    gh api repos/<org>/ghec-ch11-juice-shop/secret-scanning/alerts \
      --jq '.[] | select(.push_protection_bypassed==true) | {number, secret_type, by: .push_protection_bypassed_by.login}'
    ```
14. **Write a one-paragraph triage summary** (drop it in an issue on the repo): how many secrets were found, how each was resolved, that push protection blocked a fresh secret, and who bypassed it and why. This is the artifact a real security review would ask for.

## Validation / Definition of Done
You are done when ALL of the following are true:
- [ ] `secret_scanning` **and** `secret_scanning_push_protection` both read `enabled` on `ghec-ch11-juice-shop` (verifiable via the `security_and_analysis` API).
- [ ] **Every planted secret in `SECRETS-MANIFEST.md` has a corresponding secret-scanning alert** (count + types reconcile).
- [ ] **All alerts are resolved** with an explicit, correct resolution reason (none left `open`).
- [ ] You **demonstrated push protection blocking** a fresh secret at `git push` (and a clean push after removing it).
- [ ] At least **one push-protection bypass** exists with a recorded actor and reason (verifiable via the alerts API).
- [ ] A **custom secret-scanning pattern** is published and raised at least one alert.
- [ ] A **triage summary** issue exists on the repo.
- [ ] Real-outcome check — if you brought your own repo, scanning + push protection are now enabled on a project you actually own; if you used the sample, you can name the real repo you'll roll this out to next.
- [ ] Coach conversation — if you turned push protection on across your real org tomorrow, whose workflow breaks first and what secret would it have caught in your last six months of commits? Talk it through with your coach and connect it to a real project, task, or workflow you own.

> Coaches verify these via the automated hints in `COACH.md`.

## Stretch goals
- Enable scanning for **non-provider patterns / generic passwords** and triage the noisier results — discuss precision vs recall.
- Configure secret scanning at the **org security configuration** level and apply it to all new repos, then confirm `ghec-ch11-juice-shop` inherits it.
- Wire an **alert webhook** (`secret_scanning_alert` event) to a small endpoint and prove a new alert fires a notification (pairs with ch17).

## Reference links
- About secret scanning — https://docs.github.com/en/code-security/secret-scanning/about-secret-scanning
- Configuring secret scanning for your repositories — https://docs.github.com/en/code-security/secret-scanning/enabling-secret-scanning-features/enabling-secret-scanning-for-your-repository
- Protecting pushes with secret scanning — https://docs.github.com/en/code-security/secret-scanning/introduction/about-push-protection
- Managing alerts from secret scanning — https://docs.github.com/en/code-security/secret-scanning/managing-alerts-from-secret-scanning
- Defining custom patterns for secret scanning — https://docs.github.com/en/code-security/secret-scanning/using-advanced-secret-scanning-and-push-protection-features/custom-patterns/defining-custom-patterns-for-secret-scanning
- Secret scanning REST API — https://docs.github.com/en/rest/secret-scanning/secret-scanning
