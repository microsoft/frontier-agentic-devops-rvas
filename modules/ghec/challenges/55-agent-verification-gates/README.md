# Ch55: Agent verification gates

**Session outcome:** One agent-written pull request passes through tests, code scanning, code quality, and Copilot review, and a human decides what each result means. You know which of these checks block a merge and which only advise.

**"Green" only means something if the checks can fail.** An agent can write code and the tests that pass it. Your gates must catch that.

## The stack

| Gate | Blocks merge? | Catches |
|---|---|---|
| Tests (CI) | Yes, as a required check | Broken behavior |
| CodeQL code scanning | Yes, through ruleset code scanning results | Security flaws in new code |
| Code quality (ch27) | Set by policy | Maintainability issues |
| Copilot code review (ch32) | No. It only comments. | Logic slips and missed cases |
| Human review | Yes, per risk tier (ch53) | Intent, design, risk |

## Tasks

### Part A: Confirm the blockers

1. In the repository ruleset, check that CI and the CodeQL code scanning result are **required**. Add them if not. Set the alert thresholds with the security owner.
2. Confirm CodeQL runs on pull requests, including those opened by the agent.
3. Check what happens on an agent pull request: by default, a maintainer approves its workflow runs. Leave that on.

### Part B: Make the tests hard to fool

4. Look at the agent pull request's tests. Ask of each: **would this fail if the code were wrong?** Reject tests that only assert the code returns what it returns.
5. Run the suite against a deliberate bug. Change one condition in the new code, then rerun. If everything stays green, the tests don't cover that branch.
6. Optional: run a mutation tool for your language on the changed files and record the surviving mutants.

### Part C: Read the machine reviews

7. Request Copilot review on the pull request (ch32). Classify each comment as accepted, rejected with a reason, or noise.
8. Open any CodeQL alert on the pull request. Where **Copilot Autofix** offers a patch, review it as you would a human's. Don't commit it unread.
9. Check code quality findings on the changed files.

### Part D: Add a runtime check

10. If you have preview environments, run a smoke test against the pull request's deployment. If not, record the gap and the owner. Don't invent one for the session.

### Part E: Record the decision

11. In the pull request, write which gates ran, which blocked, and what the human reviewer decided. That note becomes the evidence for the risk tier in ch53.

## Hints

- **An agent's own passing tests prove little.** Weight your existing tests and independent checks more.
- Don't treat Copilot review as an approval. It can't satisfy a required review.
- If a gate is flaky, fix or remove it. Teams learn to ignore noisy checks, and agents learn to retry past them.

## Common failures

| Symptom | Likely cause |
|---|---|
| CodeQL doesn't run on agent pull requests | Workflow approval is pending, or scanning is on a schedule only. |
| Merge isn't blocked by alerts | The ruleset lacks a code scanning rule. |
| Review comments repeat | Review of new pushes is on. Turn it off if it adds noise. |
