# Coach Guide: Challenge 00 — Environment Setup

## Objectives
- Help students get a working `gh aw` CLI environment in Codespaces or a local dev container.
- Confirm GitHub authentication and the dry-run smoke test before students start track work.
- Surface access blockers early and route teams to a fallback path.

## Facilitation Hints
- Prefer Codespaces when local setup starts to consume too much time.
- Ask students to show both `gh auth status` and `gh aw --version` before moving on.
- If `gh aw run examples/hello-world.md --dry-run` fails, capture the exact error and unblock with the smallest next step.

## Success Check
- `gh aw --version` returns successfully.
- The hello-world dry run completes without errors.
- The learner has a repo workspace ready for the rest of the module.
