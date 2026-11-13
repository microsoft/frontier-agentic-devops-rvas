# Ch54: Agent-ready intake

**Session outcome:** Your team has an issue form that produces tasks an agent can finish, repository instructions the agent follows, and a written rule for what to hand over. You check it by assigning one real issue to Copilot cloud agent and reviewing the pull request.

An agent fails on the same things a new hire does: vague goals, missing context, and no way to know it's done. **Fix the issue, not the prompt.**

## Tasks

### Part A: Pick the work

1. Take three real backlog items. Score each:

   | Hand to an agent | Keep with a human |
   |---|---|
   | Clear acceptance criteria | Goal still debated |
   | Contained in a few files | Cross-service or architectural |
   | Existing tests can prove it | Needs production data or secrets |
   | Cheap to revert | Security- or compliance-sensitive |

2. Write the rule as three lines in `CONTRIBUTING.md`: what goes to agents, what doesn't, who decides.

### Part B: Add the issue form

3. Create `.github/ISSUE_TEMPLATE/agent-task.yml`:

   ```yaml
   name: Agent task
   description: A change an agent can complete
   labels: ["agent-ready"]
   body:
     - type: textarea
       id: goal
       attributes: { label: Goal, description: "One outcome, in one or two sentences." }
       validations: { required: true }
     - type: textarea
       id: criteria
       attributes: { label: Acceptance criteria, description: "Checkable statements, one per line." }
       validations: { required: true }
     - type: textarea
       id: scope
       attributes: { label: Files and out of scope, description: "Where to change, and what not to touch." }
     - type: textarea
       id: verify
       attributes: { label: How to verify, description: "The command or test that proves it." }
       validations: { required: true }
   ```

4. Make `verify` required. An agent that can run the check fixes its own mistakes before you see them.

### Part C: Give the agent repository context

5. Add `.github/copilot-instructions.md` with build and test commands, code conventions, and what must never change. Keep it under a page. See [first-run setup](../../resources/copilot-first-run.md) and ch31 for the environment.
6. Optional: add a custom agent in `.github/agents/` for a recurring job, such as a test writer, with a narrow instruction and tool list.

### Part D: Run one task

7. Open one issue with the form. Assign it to **Copilot**.
8. Review the pull request like any other. Check the diff against the acceptance criteria, then run your verify command.
9. If the result misses, find which form field was too vague. Fix the field, not just this issue.

## Hints

- Copilot can't approve its own pull request. The person who assigned it shouldn't be the only reviewer either.
- Workflows on agent pull requests need a maintainer to approve the run by default. Leave that on.
- Small, well-specified tasks beat big ones. Split anything you'd estimate above a day.

## Common failures

| Symptom | Likely cause |
|---|---|
| Agent changes unrelated files | The form has no out-of-scope field, or it is empty. |
| Pull request fails CI on setup | Missing `copilot-setup-steps.yml`. See ch31. |
| Agent never starts | Cloud agent is off for the repository, or the plan excludes it. |
