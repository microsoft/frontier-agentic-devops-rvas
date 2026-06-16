# Ch03 — Codespaces & Dev Containers — Coach Guide

> Audience: facilitators and graders. Pair with the student `README.md`.

## Grounding conversation (you will be called)

Students are **expected to call you** to talk through this challenge's real-world impact before they consider it done. This is a required completion step, not optional — it is how we keep the learning grounded in their actual day-to-day work.

**Their question:** Coach conversation — what is the most painful or inconsistent part of onboarding a new developer (or yourself after a fresh machine) onto your current project, and how would a Codespace with a locked devcontainer.json change that? Talk it through with your coach and connect it to a real project, task, or workflow you own.

Use these follow-ups to steer the conversation:
- Tell me about a specific repo or project where environment setup causes the most friction — what usually breaks?
- If you shipped a Codespace for that repo today, what would still not work out of the box?
- What is the single .devcontainer change you could open a PR for before next week?

## Facilitation notes
- **Goal in one line:** the student makes "clone and code in 60 seconds" real — a committed, reproducible dev container, a prebuild for speed, and an org policy that controls spend.
- **Where students get stuck:**
  - **Features vs Dockerfile.** Students conflate the two. Features are composable add-ons layered onto a base image; a Dockerfile is a full custom image. Both are valid; start with Features.
  - **Lifecycle command timing.** `postCreateCommand` runs once at create; `postStartCommand` runs on every start. Students put `npm ci` in the wrong hook and wonder why it's slow.
  - **Prebuild ≠ instant.** The prebuild is a scheduled Action that must finish *before* a new Codespace shows "prebuilt." Have them wait for the prebuild run to go green.
  - **Cost anxiety / forgotten Codespaces.** Emphasize stop/delete. Idle Codespaces bill storage.
- **How to unblock without giving the answer:** ask "what should every teammate get identically, and what's just *your* preference?" (→ devcontainer vs dotfiles), and "where did the time go on first start vs after a prebuild?"
- **Org-scoped note:** runs with just an org + org-owner token. The org policy + prebuild steps need `admin:org`, which the org-owner token has. **This is a metered challenge** — make participants aware before they launch.

## Grading rubric (point-weighted, 100 pts)
| Criterion | Points | What "full marks" looks like |
|---|---:|---|
| devcontainer.json quality | 25 | Pinned base image, ≥2 Features, both lifecycle hooks, committed extensions |
| Launch + verify (UI + CLI) | 20 | Codespace created both ways; node version, gh Feature, post-create install all verified inside |
| Ports | 15 | App runs; port forwarded + labeled; `forwardPorts`/`portsAttributes` committed; visibility changed |
| Personalization understanding | 10 | `docs/devcontainer-notes.md` correctly explains dotfiles vs devcontainer precedence |
| Org policy | 15 | Machine-type restriction + retention set at org scope |
| Prebuild + cleanup | 15 | Prebuild configured, new Codespace reports prebuilt; all Codespaces deleted at end |
| **Total** | **100** | |

## Automated verification hints
```bash
ORG=<org>; REPO=wth-ch03-codespaces-dev-containers

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
- For the prebuild, look for a successful run of the **"Create codespace prebuilds"** workflow and have the student show a new Codespace's creation log saying *prebuilt*.

## Common pitfalls
- **`:latest` base image** defeats reproducibility — dock points if not pinned.
- **Prebuild region/branch mismatch** — prebuilds attach to a branch + region; a Codespace in a different region won't be prebuilt.
- **Leftover Codespaces** keep billing. Verify `gh codespace list` is empty at teardown.
- **Token missing `codespace`/`admin:org`** — policy and codespace API calls 403.

## Teardown
```bash
wth teardown ch03 --org <org> --yes
./scripts/teardown.sh ch03 --org <org> --yes   # Bash
./scripts/teardown.ps1 ch03 --org <org> --yes  # PowerShell
```
- Removes only `wth-ch03-*` artifacts (prefix-guarded): the repo and its prebuild config.
- **Manual cleanup (required):** running/stopped **Codespaces are billed** and may not be auto-deleted by teardown if created under a personal account — teardown prints `gh codespace list`; delete each with `gh codespace delete`. The **org Codespaces policy** change is an org setting; revert manually if desired.

## Time budget
- Setup + read: ~30 min
- Part A (author devcontainer): ~1 hr
- Parts B–C (launch, run, ports): ~1 hr
- Part D (personalization notes): ~20 min
- Part E (org policy + prebuild): ~1.5 hrs (prebuild Action wait)
- **Total facilitated:** ~4–5 hrs across sessions.
