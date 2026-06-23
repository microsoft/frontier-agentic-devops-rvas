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
- If `gh aw run ... --dry-run` fails with an API key error, GitHub Copilot is the default zero-config engine. Confirm the participant's account has an active Copilot subscription. For Claude/OpenAI/Gemini, point them to `github.com/settings/codespaces` to add secrets.

---

## Common Blockers & Fixes

| Symptom | Cause | Fix |
|---|---|---|
| `gh auth status` fails | Not logged in | Run `gh auth login` again; choose HTTPS |
| Codespace build times out | Network / quota | Retry once; fall back to local dev container |
| `gh aw --version` not found | Container image stale or `postCreate.sh` failed | Rebuild container (`Ctrl+Shift+P → Dev Containers: Rebuild Container`); or run `curl -sL https://raw.githubusercontent.com/github/gh-aw/main/install-gh-aw.sh \| bash` manually |
| `gh aw run modules/ghaw/resources/examples/hello-world.md --dry-run` fails | AI engine key missing | Confirm Copilot subscription is active; or set `ANTHROPIC_API_KEY` / `OPENAI_API_KEY` / `GEMINI_API_KEY` as Codespace secrets and rebuild |
| Repository not accessible | Not in the right repo | Confirm the Codespace or local clone is for `microsoft/frontier-agenticdevops-hackathon` |

---

## Success Check

Before releasing the group to Challenge 1-01, confirm per participant:

- [ ] `gh auth status` exits 0 and shows the correct username
- [ ] `gh aw --version` returns a version string
- [ ] `gh aw run modules/ghaw/resources/examples/hello-world.md --dry-run` completes without errors
- [ ] Repository is open and writable (or readable with a documented fallback)

---

## Access-Blocked Fallback

If a participant cannot reach the environment, apply the smallest unblock:

1. **Codespaces quota:** Use local dev container or request org Codespaces billing.
2. **Repo access:** Participants work directly in `microsoft/frontier-agenticdevops-hackathon`. If GitHub is network-blocked, provide a pre-cloned repo baseline branch.
3. **`gh aw` install blocked:** Coach provides a pre-built binary or runs the install script from a terminal with outbound access. As a last resort, install from source: `go install github.com/github/gh-aw@latest`.
4. **AI engine key missing:** GitHub Copilot is the default and zero-config if the participant's account has an active subscription. For Claude/OpenAI/Gemini, set secrets at `github.com/settings/codespaces` and rebuild the Codespace.
