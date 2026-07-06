# Ch12 — Code Scanning with CodeQL & Autofix

> By the end of this challenge you can turn on CodeQL code scanning two ways (default setup and an advanced workflow), triage real vulnerability alerts in OWASP Juice Shop, apply Copilot Autofix, and gate pull requests on clean code-scanning results — all org-scoped on a public repo.

| | |
|---|---|
| **Track** | Security |
| **Difficulty** | Intermediate *(per-track ramp)* |
| **Duration** | ~5 hrs total, multi-session |
| **Minimum input** | An **org** + an **org-owner token**. *(All challenges are org-scoped — no enterprise owner required.)* |
| **App** | juice-shop *(imported at pinned ref `v20.0.0`; see `docs/EXTERNAL-REPOS.md`)* |
| **EMU compatible** | yes |

## Prerequisites
- An organization you own (or org-owner rights) on GitHub Enterprise Cloud.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch12 --org <org>` (least-privilege; for this challenge: `repo` + `workflow` + `security_events`).
- Local tooling: `gh >= 2.x`, `git`, `jq` (run `modules/ghec/resources/provisioning/scripts/setup.sh doctor` to verify).
- **GHAS note:** code scanning with CodeQL is **free on public repos**. Setup provisions the Juice Shop import as **public**. On private/internal repos CodeQL needs a paid Code Security license — `modules/ghec/resources/provisioning/scripts/setup.sh doctor` warns. Actions minutes are consumed by scan runs (free on public).

## Scenario objectives
By completing this challenge you will:
- Enable **CodeQL default setup** and confirm an initial scan runs and produces alerts.
- Replace it with an **advanced CodeQL workflow** so you control the language matrix, query suite, and triggers.
- Target the correct language pack — **`javascript-typescript`** — for Juice Shop's Angular + Node/Express stack.
- Triage **code-scanning alerts**: read the data-flow path, set severity/priority, and dismiss with a reason.
- Apply **Copilot Autofix** to a suitable alert and review the suggested patch.
- Make code scanning a **required PR check** so newly introduced vulnerabilities block merges.

## Scenario
A GHEC customer ships a Node/Angular app with a backlog of latent vulnerabilities — SQL injection, XSS, broken auth, path traversal — none of them visible until something breaks in production. You'll give them static analysis that finds these on every push and every PR, explains each via its data-flow path, suggests fixes, and stops new vulnerabilities from merging. OWASP Juice Shop is the ideal target: it's intentionally riddled with the full OWASP Top 10, so CodeQL has genuine findings to surface — not toy examples.

## Bring your own outcome (do this first)
This challenge is most valuable when the result *outlives the delivery session*. Pick a real application repository your organization owns so CodeQL findings and gates matter after today and complete every task on **that** artifact. You leave with evidence, guardrails, or automation genuinely standing up on something you care about.

- **Have a candidate?** Use it everywhere this guide says `ghec-ch12-juice-shop`. Skip the Setup step below entirely.
- **No suitable one?** Use the fallback below: an OWASP Juice Shop import with known vulnerable code for safe CodeQL practice.

> Tell your coach which path you took. "Bring your own" is the goal; the sample is the fallback.

## Setup (fallback sample)
Skip this if you brought your own repo. Otherwise run the provisioning entrypoint (Bash or PowerShell — both supported).

```bash
# Bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch12 --org <org>
```
```powershell
# PowerShell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch12 --org <org>
```

**What setup creates** (all artifacts namespaced `ghec-ch12-*`, idempotent, prefix-guarded teardown):
- A **public** repo **`ghec-ch12-juice-shop`** — OWASP Juice Shop imported at pinned ref **`v20.0.0`** (pulled from the official source, never vendored into this repo). The codebase carries real, intentional OWASP Top 10 vulnerabilities (SQLi, XSS, broken auth/JWT, path traversal, SSRF, and more).
- A `feature/insecure-endpoint` **branch** with a small deliberately vulnerable change you'll open as a PR to demonstrate PR-time scanning and required-check gating.
- A printed **Next steps** block telling you where to start.


## Tasks
> Throughout, **`ghec-ch12-juice-shop` is the fallback sample**. If you brought your own artifact, substitute its name in every command and use your real history, teams, settings, or data as the material to work from.

### Part A — Default setup
1. **Enable CodeQL default setup.** In `ghec-ch12-juice-shop` → **Settings → Code security → Code scanning**, choose **Set up → Default**. Confirm it detects **JavaScript/TypeScript** as the language.
2. **Watch the first scan run.** Default setup creates a CodeQL run under the **Actions** tab. Wait for it to complete (`gh run watch`), then open **Security → Code scanning** and confirm alerts have appeared.
3. **Confirm via API** that an analysis exists:
   ```bash
   gh api repos/<org>/ghec-ch12-juice-shop/code-scanning/analyses --jq '.[0] | {tool: .tool.name, ref, created_at}'
   ```

### Part B — Switch to an advanced workflow
4. **Disable default setup** and add an **advanced CodeQL workflow**. From the same Code scanning settings choose **Advanced**, or commit `.github/workflows/codeql.yml` based on GitHub's CodeQL Action starter.
5. **Pin the language pack.** In the workflow's `strategy.matrix`, set `language: [ 'javascript-typescript' ]` (Juice Shop has no compiled/Solidity targets you need to analyze).
6. **Choose a query suite.** Set the CodeQL init step to run the **`security-extended`** query suite so you surface more than the default minimal set.
7. **Trigger and confirm.** Push the workflow, watch the run, and confirm a fresh batch of alerts (likely *more* than default setup, due to `security-extended`).

### Part C — Triage alerts
8. **Inspect a high-severity alert.** Open a **SQL injection** or **XSS** alert and read its **data-flow path** — source (user input) → sink (query/DOM). Note the rule ID and severity.
9. **Set priority and triage three alerts:** confirm one as a true positive (leave open / create a tracking issue), and dismiss one with a reason (`won't fix` / `used in tests` / `false positive`) using the UI or API:
   ```bash
   gh api -X PATCH repos/<org>/ghec-ch12-juice-shop/code-scanning/alerts/<n> \
     -f state=dismissed -f dismissed_reason="won't fix" \
     -f dismissed_comment="Demo target — tracked separately"
   ```
10. **List open alerts by severity** to build a triage view:
    ```bash
    gh api repos/<org>/ghec-ch12-juice-shop/code-scanning/alerts --paginate \
      --jq '.[] | select(.state=="open") | {number, rule: .rule.id, severity: .rule.security_severity_level}'
    ```

### Part D — Copilot Autofix
11. **Apply Autofix.** Open an alert that offers a **Copilot Autofix** suggestion (XSS and injection alerts commonly do). Read the proposed patch and the explanation of *why* it fixes the data-flow.
12. **Commit the fix to a branch** (Autofix can commit its suggestion to a branch) and confirm the alert moves toward resolution once the fix is scanned. Note where Autofix is and isn't confident — this is a judgment skill, not auto-trust.

### Part E — Gate pull requests
13. **Open the seeded vulnerable PR.** Create a PR from `feature/insecure-endpoint` into `main`. The PR-triggered CodeQL run should flag the new vulnerability **inline on the diff**.
14. **Make code scanning required.** In branch protection / a ruleset on `main`, mark the **CodeQL code-scanning results check as required**. Confirm the vulnerable PR is now **blocked from merging** while the alert is open, and that fixing/dismissing it clears the gate.

## Validation / Definition of Done
You are done when ALL of the following are true:
- [ ] CodeQL is enabled via an **advanced workflow** scanning **`javascript-typescript`** with the `security-extended` suite (visible in `.github/workflows/codeql.yml`).
- [ ] At least one completed **CodeQL analysis** exists (verifiable via the `code-scanning/analyses` API).
- [ ] The repo has **open code-scanning alerts** including at least one injection/XSS finding with a readable data-flow path.
- [ ] You **triaged ≥3 alerts** (one dismissed with a reason via API; others reviewed).
- [ ] You applied **Copilot Autofix** to at least one alert and reviewed the suggested patch.
- [ ] The **code-scanning check is required** on `main`, and the seeded vulnerable PR is **blocked** until the alert is resolved/dismissed.
- [ ] Real-outcome check — if you brought your own repo, CodeQL analysis and PR gating now protect code you actually ship; if you used the sample, you can name the application repo you will enable next.
- [ ] Coach conversation — pick a codebase you own or contribute to: what class of vulnerability (injection, path traversal, auth bypass) do you most fear is hiding there right now, and how would a CodeQL custom query surface it before your next release? Talk it through with your coach and connect it to a real project, task, or workflow you own.

> Coaches verify these via the automated hints in `COACH.md`.

## Stretch goals
- Add a **custom CodeQL query** (or a query filter) and run it through the advanced workflow.
- Use **`category`** in the workflow to scan multiple configurations and keep their alerts separate.
- Upload **third-party SARIF** alongside CodeQL and confirm both tools' alerts coexist in the Security tab.

## Reference links
- About code scanning — https://docs.github.com/en/code-security/code-scanning/introduction-to-code-scanning/about-code-scanning
- Configuring default setup for code scanning — https://docs.github.com/en/code-security/code-scanning/enabling-code-scanning/configuring-default-setup-for-code-scanning
- Configuring advanced setup for code scanning — https://docs.github.com/en/code-security/code-scanning/creating-an-advanced-setup-for-code-scanning/configuring-advanced-setup-for-code-scanning
- Customizing your advanced setup for code scanning — https://docs.github.com/en/code-security/code-scanning/creating-an-advanced-setup-for-code-scanning/customizing-your-advanced-setup-for-code-scanning
- Responsible use of Copilot Autofix for code scanning — https://docs.github.com/en/code-security/code-scanning/managing-code-scanning-alerts/responsible-use-autofix-code-scanning
- About code scanning alerts — https://docs.github.com/en/code-security/code-scanning/managing-code-scanning-alerts/about-code-scanning-alerts
- Code scanning REST API — https://docs.github.com/en/rest/code-scanning/code-scanning
