# Ch57: Maintenance agents

**Session outcome:** Dependency updates and one more recurring chore reach the repository as small pull requests that ch53 routes to merge or review. You verify one of each, plus a run that should do nothing.

Maintenance suits agents: the work is repetitive, tests can check it, and a bad change is easy to revert.

## Tasks

### Part A: Start with Dependabot

Dependabot is the cheapest maintenance agent. Use it before writing one.

1. Add `.github/dependabot.yml` for each ecosystem you use. Set a weekly schedule and **group** updates, for example minor and patch updates together, to cut pull request count.
2. Check that Dependabot pull requests run your required checks and receive a `risk:` label from ch53.
3. Confirm a patch update lands as `risk:low` and merges when checks pass. Confirm a major update waits for review.

### Part B: Pick one more chore

4. Choose one recurring chore with a clear check. Good candidates:
   - fixing a flaky test the team already knows;
   - a framework upgrade of one minor version;
   - updating stale docs after code changes (see ghaw-19).
5. Pick the trigger. Use a schedule or a label, not "every push".
6. Write the instructions to the agent as an issue with the ch54 form. For a recurring chore, start from a gh-aw starter in `modules/ghaw/resources/examples/` and compile it with `gh aw compile`.
7. Allow it to open **pull requests only**. It must not push to the default branch.

### Part C: Run, then check the stop case

8. Run it manually and review the pull request. Check the tier it received.
9. Run it again when there's nothing to do. Expect no pull request. If it opens an empty or duplicate one, fix the instructions before you add a schedule.
10. Add the schedule only after both runs behave. Name the person who watches for failed runs.

## Hints

- Keep each pull request to one concern. Merge or reject it quickly.
- If an agent's pull requests are rejected more than they merge, stop the chore. Check ch58 for the numbers.
- Use ordinary Actions or Dependabot for fixed rules. Use an agent for work that needs judgment.

## Common failures

| Symptom | Likely cause |
|---|---|
| Dependabot floods the queue | Updates aren't grouped, or the open pull request limit is high. |
| Agent pull request skips CI | Workflow runs await maintainer approval. |
| Duplicate pull requests | The chore has no check for an existing open pull request. |
