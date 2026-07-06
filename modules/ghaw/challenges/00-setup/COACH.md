# Coach Guide: Challenge 00 — Environment Setup

## Objectives

- Help every participant reach a verified working environment (Codespaces or local dev container).
- Confirm `gh` CLI authentication and the `gh aw` smoke test before track work begins.
- Surface and document access blockers early; apply fallback paths before Challenge 1-01.

---

## Facilitation Hints

- **Push Codespaces first.** If local setup consumes more than 10 minutes, redirect to Codespaces.
- Ask for a show-of-hands "green terminal" check after the first 10 minutes.
- Pair any participant who is blocked with a working neighbor; don't let one blocker stall the group.
- `gh aw` installs automatically via `postCreate.sh` in both Codespaces and local dev containers. If a participant sees "command not found", the postCreate script likely failed — have them rebuild the container.
- If `gh aw trial ... --dry-run` fails with an API key error, GitHub Copilot is the default zero-config engine. Confirm the participant's account has an active Copilot subscription. For Claude/OpenAI/Gemini, point them to `github.com/settings/codespaces` to add secrets.
- If `gh aw trial ... --dry-run` fails with "failed to determine simulated host repository", make sure the command includes `--logical-repo microsoft/frontier-agentic-devops-rvas`. This avoids relying on the participant's local Git remote URL, which may use a custom SSH host alias.
- Students do not need write access to `microsoft/frontier-agentic-devops-rvas` for the trial smoke test. `gh-aw` creates or uses a trial host repository in the student's own GitHub account and only simulates the delivery session repository as the target.

---

## Common Blockers & Fixes

| Symptom | Cause | Fix |
|---|---|---|
| `gh auth status` fails | Not logged in | Run `gh auth login` again; choose HTTPS |
| Codespace build times out | Network / quota | Retry once; fall back to local dev container |
| `gh aw --version` not found | Container image stale or `postCreate.sh` failed | Rebuild container (`Ctrl+Shift+P → Dev Containers: Rebuild Container`); or run `curl -sL https://raw.githubusercontent.com/github/gh-aw/main/install-gh-aw.sh \| bash` manually |
| `gh aw trial modules/ghaw/resources/examples/hello-world.md --logical-repo microsoft/frontier-agentic-devops-rvas --dry-run --yes` fails with API key error | AI engine key missing | Confirm Copilot subscription is active; or set `ANTHROPIC_API_KEY` / `OPENAI_API_KEY` / `GEMINI_API_KEY` as Codespace secrets and rebuild |
| `gh aw trial ... --dry-run` fails with `failed to determine simulated host repository` | Local Git remote uses a custom SSH host alias or another URL `gh-aw` cannot parse | Re-run with `--logical-repo microsoft/frontier-agentic-devops-rvas`; do not ask participants to change remotes unless they need to |
| Cannot write to `microsoft/frontier-agentic-devops-rvas` | Expected for students using the public repo | No action needed for the smoke test; trial mode writes to the student's trial host repository, not the delivery session repo |
| Repository not accessible | Not in the right repo or public repo access is blocked | Confirm the Codespace or local clone is for `microsoft/frontier-agentic-devops-rvas` |

---

## Success Check

Before releasing the group to Challenge 1-01, confirm per participant:

- [ ] `gh auth status` exits 0 and shows the correct username
- [ ] `gh aw --version` returns a version string
- [ ] `gh aw trial modules/ghaw/resources/examples/hello-world.md --logical-repo microsoft/frontier-agentic-devops-rvas --dry-run --yes` completes without errors
- [ ] Repository is open and writable (or readable with a documented fallback)

---

## Access-Blocked Fallback

If a participant cannot reach the environment, apply the smallest unblock:

1. **Codespaces quota:** Use local dev container or request org Codespaces billing.
2. **Repo access:** Participants work directly in `microsoft/frontier-agentic-devops-rvas`. If GitHub is network-blocked, provide a pre-cloned repo baseline branch.
3. **`gh aw` install blocked:** Coach provides a pre-built binary or runs the install script from a terminal with outbound access. As a last resort, install from source: `go install github.com/github/gh-aw@latest`.
4. **AI engine key missing:** GitHub Copilot is the default and zero-config if the participant's account has an active subscription. For Claude/OpenAI/Gemini, set secrets at `github.com/settings/codespaces` and rebuild the Codespace.
