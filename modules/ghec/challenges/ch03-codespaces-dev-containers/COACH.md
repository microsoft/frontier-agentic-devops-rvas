# Ch03 — Codespaces & Dev Containers — Delivery Assurance Guide

> Audience: delivery assurance leads and authorized customer implementation owners. Pair with the corresponding customer implementation `README.md`.
> **Customer authorization and rollout boundary:** Apply changes in a customer-owned tenant or repository only after the named customer owner authorizes the scope. A fallback is a sample test repository or environment, not the destination: record its evidence, risks and controls, accountable owner, handover, and the explicit tenant adoption, cutover, or rollout decision.


## Customer adoption decision

**Required delivery assurance check:** before implementation is accepted, confirm the authorized tenant scope, implementation evidence, risk controls, accountable owner, handover, and next adoption action.

**Decision prompt:** what is the most painful or inconsistent part of onboarding a new developer (or yourself after a fresh machine) onto your current project, and how would a Codespace with a locked devcontainer.json change that? Record the accountable owner, implementation evidence, risk or blocker, and next customer adoption action.

> **Customer implementation preference:** prioritize an authorized customer tenant or artifact over the `ghec-ch03-codespaces-dev-containers` sample. If a sample is necessary, record the target tenant scope, accountable owner, authorization blocker, evidence to carry forward, and the adoption, cutover, or rollout decision. The sample is a safe fallback, not the destination.

Use these prompts to verify customer ownership and the next action:
- Tell me about a specific repo or project where environment setup causes the most friction — what usually breaks?
- If you shipped a Codespace for that repo today, what would still not work out of the box?
- What is the single .devcontainer change you could open a PR for before next week?

## Delivery assurance notes
- **Customer adoption outcome:** the customer implementation owner makes "clone and code in 60 seconds" real — a committed, reproducible dev container, a prebuild for speed, and an org policy that controls spend.
- **Implementation risks to verify:**
  - **Features vs Dockerfile.** Customer implementation owners conflate the two. Features are composable add-ons layered onto a base image; a Dockerfile is a full custom image. Both are valid; start with Features.
  - **Lifecycle command timing.** `postCreateCommand` runs once at create; `postStartCommand` runs on every start. Customer implementation owners put `npm ci` in the wrong hook and wonder why it's slow.
  - **Prebuild ≠ instant.** The prebuild is a scheduled Action that must finish *before* a new Codespace shows "prebuilt." Have them wait for the prebuild run to go green.
  - **Cost anxiety / forgotten Codespaces.** Emphasize stop/delete. Idle Codespaces bill storage.
- **Delivery lead prompts:** ask "what should every teammate get identically, and what's just *your* preference?" (→ devcontainer vs dotfiles), and "where did the time go on first start vs after a prebuild?"
- **Org-scoped note:** runs with just an org + org-owner token. The org policy + prebuild steps need `admin:org`, which the org-owner token has. **This is a metered implementation** — confirm cost ownership before launch.

## Implementation acceptance evidence
| Criterion | Assurance weight | Customer-owned evidence |
|---|---:|---|
| devcontainer.json quality | 25 | Pinned base image, ≥2 Features, both lifecycle hooks, committed extensions |
| Launch + verify (UI + CLI) | 20 | Codespace created both ways; node version, gh Feature, post-create install all verified inside |
| Ports | 15 | App runs; port forwarded + labeled; `forwardPorts`/`portsAttributes` committed; visibility changed |
| Personalization understanding | 10 | `docs/devcontainer-notes.md` correctly explains dotfiles vs devcontainer precedence |
| Org policy | 15 | Machine-type restriction + retention set at org scope |
| Prebuild + cleanup | 15 | Prebuild configured, new Codespace reports prebuilt; all Codespaces deleted at end |
| **Assurance coverage** | **100** | |

## Implementation verification evidence
```bash
ORG=<org>; REPO=ghec-ch03-codespaces-dev-containers   # swap REPO for the customer implementation owner's own repo if they brought one

# devcontainer.json present and pins an image + has features
gh api repos/$ORG/$REPO/contents/.devcontainer/devcontainer.json --jq '.path'
gh api repos/$ORG/$REPO/contents/.devcontainer/devcontainer.json -H "Accept: application/vnd.github.raw" | jq '{image, features: (.features|keys), postCreateCommand, postStartCommand}'

# Codespaces created against this repo (and that they get cleaned up)
gh codespace list --json name,repository,state,gitStatus

# Org-level codespaces policy / settings
gh api /orgs/$ORG/codespaces --jq '.total_count'           # billing/usage surface
# Prebuild config (Actions runs named "Create codespace prebuilds")
gh run list --repo $ORG/$REPO --workflow "Create codespace prebuilds" --json status,conclusion 2>/dev/null

# Notes doc present
gh api repos/$ORG/$REPO/contents/docs/devcontainer-notes.md --jq '.path'
```
- The fastest mastery signal is the **raw devcontainer.json**: confirm `image` is version-pinned (not `:latest`), `features` has ≥2 entries, and both lifecycle hooks exist.
- For the prebuild, look for a successful run of the **"Create codespace prebuilds"** workflow and have the customer implementation owner show a new Codespace's creation log saying *prebuilt*.

## Common pitfalls
- **`:latest` base image** defeats reproducibility — dock points if not pinned.
- **Prebuild region/branch mismatch** — prebuilds attach to a branch + region; a Codespace in a different region won't be prebuilt.
- **Leftover Codespaces** keep billing. Verify `gh codespace list` is empty at teardown.
- **Token missing `codespace`/`admin:org`** — policy and codespace API calls 403.

## References for delivery leads

- [Introduction to dev containers](https://docs.github.com/en/codespaces/setting-up-your-project-for-codespaces/adding-a-dev-container-configuration/introduction-to-dev-containers), [devcontainer.json reference](https://containers.dev/implementors/json_reference/).

## Teardown
```bash
bash modules/ghec/resources/provisioning/scripts/setup.sh teardown ch03 --org <org> --yes   # Bash
modules/ghec/resources/provisioning/scripts/setup.ps1 teardown ch03 --org <org> --yes  # PowerShell
```
- Removes only `ghec-ch03-*` artifacts (prefix-guarded): the repo and its prebuild config.
- **Manual cleanup (required):** running/stopped **Codespaces are billed** and may not be auto-deleted by teardown if created under a personal account — teardown prints `gh codespace list`; delete each with `gh codespace delete`. The **org Codespaces policy** change is an org setting; revert manually if desired.

## Time budget
- Setup + read: ~30 min
- Part A (author devcontainer): ~1 hr
- Parts B–C (launch, run, ports): ~1 hr
- Part D (personalization notes): ~20 min
- Part E (org policy + prebuild): ~1.5 hrs (prebuild Action wait)
- **Indicative implementation effort:** ~4–5 hrs across sessions.
