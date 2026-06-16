# Challenge 1-02: Safe & Sound

**Track:** Track 1 — Hello, Agent  
**Difficulty:** 🟢 Beginner  
**Estimated time:** 30 minutes  
**Prerequisites:** Challenge 00 — Setup & Hello, Agent, Challenge 1-01 — Morning Briefing

---

## What You'll Build

A workflow that demonstrates the power and safety of the `safe-outputs` gate. You'll write a workflow that analyzes the repo and—*conditionally*—creates an issue only if a specific condition is met. If the condition isn't met, the workflow must explicitly call `noop` (no operation) to signal "I ran but didn't need to do anything." This teaches you that **every gh-aw workflow must declare its intent to GitHub**.

**Why this matters:** Safe-outputs is the guardrail that makes gh-aw safe for production. It ensures every write is intentional, auditable, and subject to scope restrictions. Learning to use it—and understanding `noop`—is the foundation for trusting AI in your automation.

---

## Goals

By the end of this challenge, your squad will:

1. ✅ Understand that **every workflow must have at least one safe-output action**
2. ✅ Write conditional logic in the workflow body (natural language, not code)
3. ✅ Use `safe-outputs: create-issue:` to declare your write intent
4. ✅ Use `safe-outputs: noop:` when no write is needed
5. ✅ Scope permissions to minimal required access (read-only in most cases)

---

## Success Criteria

- [ ] Workflow file `.github/workflows/safe-sound.md` exists
- [ ] Frontmatter includes **both** `safe-outputs: create-issue:` **and** `safe-outputs: noop:`
- [ ] Permissions are set to `contents: read` or a similarly restrictive scope
- [ ] Workflow body contains natural-language conditional logic (e.g., "If the repo has no TODO comments, call noop. If it has >10 TODOs, create an issue.")
- [ ] `.github/workflows/safe-sound.lock.yml` exists after compilation
- [ ] When manually triggered in a state where noop applies, the workflow succeeds but no issue is created
- [ ] When manually triggered in a state where issue creation applies, an issue is created
- [ ] Logs show which path (noop or create-issue) the agent chose
- [ ] Coach conversation — where in your own automation would an explicit safe-outputs gate and a deliberate noop give you the confidence to let an agent write without a human watching every run? Talk it through with your coach and connect it to a real project, task, or workflow you own.

---

## Tips & Hints

- **Two-path design:** Your workflow should have two possible outputs: (1) create an issue, or (2) call noop. The agent decides based on your instructions.
- **Natural language conditions:** Write something like: "Scan the repo for TODOs. If there are more than 5, create an issue listing them. Otherwise, call noop."
- **Noop is not a failure:** When the workflow calls `noop`, it's a success. Logs will show `noop called` — that's the signal that everything worked as intended.
- **Safe-outputs gate:** Even if your agent code is perfect, if you forget to declare safe-outputs, the workflow fails. This is intentional—it prevents accidental writes.
- **Permissions should be boring:** Don't overthink it. Use `contents: read` unless you have a specific reason for more access (you don't in this challenge).

---

## References

- **Safe Outputs Reference:** https://github.github.com/gh-aw/reference/safe-outputs/
- **Noop Pattern (Dossier):** See Pitfall #1 in Challenge Research Dossier — Section 6 for the mandatory noop pattern
- **Permissions Scoping:** https://github.github.com/gh-aw/reference/permissions/
- **GitHub Actions Permissions Context:** https://docs.github.com/en/actions/security-guides/automatic-token-authentication
- **Related Workflow:** `metrics-collector.md` from gh-aw repo — a pure data-collection workflow that always calls `noop`

---

## Stuck?

If you're blocked for more than **15 minutes**:

1. **Did you declare both safe-outputs?** Frontmatter must include both `create-issue:` and `noop:`. If only one is present, the workflow may fail.
2. **Check your indentation:** YAML is whitespace-sensitive. `safe-outputs:` should be at the top level of frontmatter, with sub-items indented consistently.
3. **Manually trigger and read logs:** Add `workflow_dispatch:` to test without waiting. The logs will tell you which path the agent took.
4. **Simplify your conditions:** Start with a trivial condition like "count the number of files in the repo. If >10, create issue. Else noop."
5. **Test the noop path first:** It's easier to verify that `noop` works than to verify issue creation. Once noop succeeds, flip the condition to test issue creation.

Ask your coach.
